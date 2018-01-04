using System;
using System.Drawing;
using System.Windows.Forms;
using System.Threading;
using AForge.Video.DirectShow;

using System.IO;
using System.Speech.Synthesis;//语音合成
using HandORG;//手势识别
using MathWorks.MATLAB.NET.Arrays;//Matlab必要
using System.Text;

namespace RoshamboRobotWinform
{
    public partial class Form1 : Form
    {   

        #region 摄像头相关
        FilterInfoCollection videoDevices;
        VideoCaptureDevice videoSource;
        bool webcamIsInitialized = false;
        public int selectedDeviceIndex = 0;
        #endregion

        #region 计时器相关
        System.Windows.Forms.Timer timer1;//用来滚动标签
        System.Windows.Forms.Timer timer2;//用来倒计时

        private int countdown = 3;//倒计时最大秒
        string S = "石头";
        string J = "剪刀";
        string B = " 布";//注意前面有一个空格
        Random random;//在HumMode下进行随机应对
        int chang = 3;//用来控制在石头剪刀布之间滚动
        string You = "石头";
        string Robot = "石头";
        #endregion
        bool GameMode = false;//游戏模式：false为天神模式，true为随机模式
        private SpeechSynthesizer synthesizer;//语音合成器
        Operate operate;//手势识别器
        MWNumericArray matrix;

        public Form1()
        {
            InitializeComponent();
            #region 初始化语音合成器
            synthesizer = new SpeechSynthesizer
            {
                Rate = 2//语速
                
            };
            #endregion

            #region 初始化计时器
            timer1 = new System.Windows.Forms.Timer
            {
                Enabled = true,
                Interval=1000

            };
            timer1.Tick += Timer1_Tick;
            timer1.Stop();

            timer2 = new System.Windows.Forms.Timer
            {
                Enabled = true,
                 Interval = 50
            };
            timer2.Tick += Timer2_Tick;
            timer2.Stop();


            #endregion

            try
            {
                operate = new Operate();
            }
            catch (Exception)
            {

                ResultLabel.Text = "MCR异常";
                StartButton.Enabled = false;
            }
            //初始化手势识别器
           
            //初始化随机数
            random = new Random();
        }   
        private void Timer2_Tick(object sender, EventArgs e)//实现结果滚动效果
        {
            ChangeSJB();
        }
        public void ChangeSJB()//石头剪刀布滚动
        {
            switch (chang)
            {
                case 3:
                    RbResult.Text = S;
                    HmResult.Text = B;
                    chang--;
                    break;
                case 2:
                    RbResult.Text = J;
                    HmResult.Text = J;
                    chang--;
                    break;
                case 1:
                    RbResult.Text = B;
                    HmResult.Text = S;
                    chang = 3;
                    break;

            }
        }
        void Timer1_Tick(object sender, EventArgs e)//滚动标签事件
        {
            Countdown();
        }
        private void Countdown()//倒计时
        {
            if (countdown > 0)
            {
                StartButton.Enabled = false;//防止连续点击
                synthesizer.SpeakAsync(countdown.ToString());//报数  
                TimeBlock.Text = countdown.ToString();    
                countdown--;
            }

            if (countdown<=0)
            {
                countdown--;
                if (countdown == -2)
                {
                    timer2.Stop();
                    HmResult.Text = "----";
                    RbResult.Text = "----";
                    
                }

                if (countdown == -3)
                {
                    StartGame();
                }
                
            }


        }
        private void Form1_Load(object sender, EventArgs e)//窗体加载事件
        {

            try
            {
                // 枚举所有视频输入设备
                videoDevices = new FilterInfoCollection(FilterCategory.VideoInputDevice);

                if (videoDevices.Count == 0)
                    throw new ApplicationException();

                foreach (FilterInfo device in videoDevices)
                {
                    tscbxCameras.Items.Add(device.Name);
                }

                tscbxCameras.SelectedIndex = 0;

                webcamIsInitialized = true;

            }
            catch (ApplicationException)
            {
                webcamIsInitialized = false;
                tscbxCameras.Items.Add("No local capture devices");
                videoDevices = null;
            }

            try
            {
                videoDevices = new FilterInfoCollection(FilterCategory.VideoInputDevice);
                selectedDeviceIndex = 0;
                videoSource = new VideoCaptureDevice(videoDevices[selectedDeviceIndex].MonikerString);//连接摄像头。
                videoSource.VideoResolution = videoSource.VideoCapabilities[selectedDeviceIndex];
                videoSourcePlayer1.VideoSource = videoSource;
                videoSourcePlayer1.Start();
            }
            catch (Exception)
            {

                ResultLabel.Text = "无摄像头";
            }

        }
        private void StartButton_Click(object sender, EventArgs e)//开局按钮
        {   
                timer2.Start();//开始倒计时
                timer1.Start();//滚动双方标签        
        }
        private void StartGame()
        {

            timer1.Stop();

            TimeBlock.Text = "开始";
            StartButton.Enabled = true;
            countdown = 3;
         
            if (webcamIsInitialized)
            {
       
                Bitmap bitmap = videoSourcePlayer1.GetCurrentVideoFrame();//获取当前帧

                if (bitmap == null)
                {
                    ResultLabel.Text = "无法获取当前帧";
                }
                else
                {
                    PreviewPictBox.Image = bitmap;
                    PreviewPictBox.Visible = true;
                    var height = bitmap.Height;
                    var width = bitmap.Width;
                    byte[,,] rgb = new byte[3, height, width];

                    for (int i = 0; i < height; i++)
                    {
                        for (int j = 0; j < width; j++)
                        {
                            rgb[0, i, j] = bitmap.GetPixel(j, i).R;
                            rgb[1, i, j] = bitmap.GetPixel(j, i).G;
                            rgb[2, i, j] = bitmap.GetPixel(j, i).B;
                        }

                    }
                    matrix = rgb;
                    try
                    {
                        MWArray result = operate.ORG(matrix);
                        string youresult = result.ToString();

                        if (GameMode)
                        {

                            HumReply(youresult);
                        }
                        else
                        {
                            RobotReply(youresult);//不会赢模式
                        }
                        Judge(You, Robot);
                    }
                    catch (Exception e)
                    {
                        string currentPath = Directory.GetCurrentDirectory();
                        string filePath = currentPath + "\\ExceptionLog.txt";
                        FileStream fs = null;
                        Encoding encoder = Encoding.UTF8;
                        byte[] bytes = encoder.GetBytes( DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") +": \n"+ e.Message);
                        if (File.Exists("ExceptionLog.txt"))
                        {

                            fs = File.OpenWrite(filePath);
                            //设定书写的开始位置为文件的末尾  
                            fs.Position = fs.Length;
                            //将待写入内容追加到文件末尾  
                            fs.Write(bytes, 0, bytes.Length);
                            fs.Close();
                            // 注：
                            //直接用记事本打开不显示换行，建议用其他文本编辑器看哈

                        }
                        else
                        {
    
                            File.Create(filePath);

                            fs = File.OpenWrite(filePath);
                            //设定书写的開始位置为文件的末尾  
                            fs.Position = fs.Length;
                            //将待写入内容追加到文件末尾  
                            fs.Write(bytes, 0, bytes.Length);
                            fs.Close();
                        }

                        ResultLabel.Text = "请调整手势";
                    }
                }




            }
            else
            {
               ResultLabel.Text = "无摄像头";
            }
        }//启动游戏逻辑
        private void RobotReply(string you)//机器人做出反应
        {
            if (you == "2")
            {
                You = "石头";
                Robot = " 布";
               
            }
            if (you == "1")
            {
                You = "剪刀";
                Robot = "石头";
            }
            if (you == "3")
            {
                You = " 布";
                Robot = "剪刀";
                
            }
            if (you == "0")
            {
                You = "?";
                synthesizer.SpeakAsync("未知手势");
            }
            RbResult.Text = Robot;
            HmResult.Text = You;
            
        }
        private void HumReply(string you)//机器人做出反应
        {

            int s=random.Next(2);

            if (you == "2")
            {
                You = "石头";

            }
            if (you == "1")
            {
                You = "剪刀";
            }
            if (you == "3")
            {
                You = "布";

            }
            if (you == "0")
            {
                You = "?";
                synthesizer.SpeakAsync("捕捉失败");
            }

            if (s == 0) Robot = "石头";
            if (s == 1) Robot = "剪刀";
            if (s == 2) Robot = "布";



            RbResult.Text = Robot;
            HmResult.Text = You;

        }
        private void Judge(string you, string robot)//输赢判断
        {
            if (you == "?")//如果未识别出
            {
                ResultLabel.Text = "手势未知";
            }
            else
            {
                if ((you == "石头" && robot == "石头") || (you == "剪刀" && robot == "剪刀") || (you == " 布" && robot == " 布"))
                {
                    ResultLabel.Text = "平";
                    synthesizer.SpeakAsync("平局，请准备");

                    Thread.Sleep(2000);
                    //下面是重新开局逻辑
                    timer1.Start();
                    timer2.Start();

                }

                if ((you == "石头" && robot == "剪刀") || (you == "剪刀" && robot == " 布") || (you == " 布" && robot == "石头"))
                {
                    ResultLabel.Text = "赢";
                    synthesizer.SpeakAsync("这不科学");

                }

                if ((you == "石头" && robot == " 布") || (you == "剪刀" && robot == "石头") || (you == " 布" && robot == "剪刀"))
                {
                    ResultLabel.Text = "输";
                    synthesizer.SpeakAsync("你输了");

                }
            }






        }
        private void HumanMode_CheckedChanged(object sender, EventArgs e)
        {
            GameMode = true;
        }
        private void GodMode_CheckedChanged(object sender, EventArgs e)
        {
            GameMode = false;
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            System.Environment.Exit(0);
        }
    }
}
