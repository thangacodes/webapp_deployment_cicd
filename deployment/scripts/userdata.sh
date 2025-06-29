{
  sudo apt-get update -y
  sudo apt-get install -y gnupg software-properties-common curl
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -y
  sudo apt-get install -y tree
  sudo apt install python3-pip
  sudo apt install python3.12-venv
  sudo apt install -y openjdk-17-jdk
  sudo apt-get install terraform -y
  echo "download tomcat tar file"
  cd /tmp/
  wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.106/bin/apache-tomcat-9.0.106.tar.gz
  echo "untar the file"
  tar -xvf apache-tomcat-9.0.106.tar.gz
  echo "rename the folder"
  mv apache-tomcat-9.0.106 app
  echo "start the service.."
  sh app/bin/startup.sh
  echo "checking tomcat log file"
  grep -i severe app/logs/catalina.out
  grep -i starting app/logs/catalina.out
} >> /tmp/user-data.log 2>&1
