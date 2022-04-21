set -e
cd $HOME

sudo apt install -y sudo file libyaml-cpp-dev build-essential cmake cmake-curses-gui libmatio-dev libfmt-dev git libgtest-dev doxygen curl libboost-system-dev git-gui python3-pip vim dialog terminator autoconf libfuse-dev bison flex net-tools openssh-server

# ROS
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

if [[ `lsb_release -cs` == "focal" ]]; then 
      
      # ROS and Gazebo install
      sudo apt update && sudo apt install -y \
      ros-noetic-ros-base ros-noetic-xacro\
      libgazebo11-dev liborocos-kdl-dev
      source /opt/ros/noetic/setup.bash
 
  fi;

if [[ `lsb_release -cs` == "bionic" ]]; then
  
      sudo apt update && sudo apt install -y \
      ros-melodic-ros-base ros-melodic-orocos-kdl ros-melodic-xacro\
      libgazebo9-dev
      source /opt/ros/melodic/setup.bash
fi;

sudo apt install -y ros-$ROS_DISTRO-urdf ros-$ROS_DISTRO-kdl-parser 
sudo apt install -y  ros-$ROS_DISTRO-eigen-conversions ros-$ROS_DISTRO-robot-state-publisher ros-$ROS_DISTRO-moveit-core 
sudo apt install -y  ros-$ROS_DISTRO-rviz ros-$ROS_DISTRO-interactive-markers ros-$ROS_DISTRO-tf-conversions ros-$ROS_DISTRO-tf2-eigen 
sudo apt install -y  qttools5-dev libqt5charts5-dev qtdeclarative5-dev 
sudo pip3 install rospkg matplotlib

# XBOT
sudo sh -c 'echo "deb http://xbot.cloud/xbot2/ubuntu/$(lsb_release -sc) /" > /etc/apt/sources.list.d/xbot-latest.list'
wget -q -O - http://xbot.cloud/xbot2/ubuntu/KEY.gpg | sudo apt-key add -  
sudo apt update
sudo apt install -y xbot2_desktop_full
sudo apt remove xbot2
source /opt/xbot/setup.sh

# Kernel & Xenomai
if [ ! -d some_scripts ]; then
  git clone -b xbot2 git@gitlab.advr.iit.it:amargan/some_scripts.git
fi
cd some_scripts
./prepare.sh

# SRC
cd $HOME
sudo pip3 install hhcm-forest
mkdir -p xbot2_ws && cd xbot2_ws
forest --init
source setup.bash
export PATH=/usr/xenomai/bin:$PATH
forest --add-recipes git@github.com:advrhumanoids/multidof_recipes.git master
forest rt_all -j8 -m xeno
