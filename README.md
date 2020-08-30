Here , I have mentioned the steps to build an entire infrastructure where in we'll run our entire webserver. All this will be accomplished using Terraform.

So for those of you who know nothing about Terraform, it's an open-source infrastructure as code software tool created by HarshiCorp that enables users to define and provision data center infrastructure using a declarative configuration language known as HashiCorp Configuration Language (HCL), or optionally JSON. Terraform manages external resources with "providers".

You can find my detailed article sbout Terraform and the project here : https://www.linkedin.com/pulse/getting-started-terraform-aarti-anand/?trackingId=g5X6RFB%2BSHy6uP9%2Fu11LbA%3D%3D

Since, it's a very basic project for those who just got to know about AWS infrastructure and creating it using Terraform, comments are provided at each step in the code for better understanding.

Before I tell you the steps, you need to install terraform in your system. I use Arch linux and so for windows, Mac or other linux distro users, you can find the installation commands in the terraform docs ( https://learn.hashicorp.com/tutorials/terraform/install-cli )

Installing Terraform in Arch :
------------------------------
  1.  Create a project folder.
  2.  Open the folder created in above step in terminal and run : wget https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip
  3.  run : ls. This will list out all the content (except hidden files and folders) of the directory.
  4.  You will see a zip file, 'terraform_0.12.26_linux_amd64.zip'. Unzip it using the command : unzip terraform_0.12.26_linux_amd64.zip
  5.  Now we have to set path. Run these two commands in order :
      5.1.  echo $"export PATH=\$PATH:$(pwd)" >> ~/.bash_profile
      5.2.  source ~/ .profile
  Now we are done with the installation and setup part. Now we can create the terraform file (extention : .tf) in the same project folder where terraform is installed. Here is the command :
                                nano task.tf      (nano is the editor. You can use yours)

And we are all set!

Steps:
  1.  Configure AWS profile. This step needs to be done through terminal. Make sure you use IAM account or else as root you will face errors and your code won't run!
  2.  Create github repo and add the image or you can add an html file with very basic code
  3.  Creating the Configuration file.
  3.  Creating public key and use it to create key-pair.
  4.  Creating Security Group.
  5.  Create and launching AWS Instance and installing requirements.
  6.  Create-attach-connect EBS Volume to the instance.
  7.  Format-mount-download the volume.
  8.  Preparing the S3 bucket.
  9.  Create Cloudfront Distro and connect it to S3 bucket.
And done!
 
Remember!
---------
Before running the code in terraform, we need to install dependencies or plugins required to run that code.
So, in the terminal, run : terraform init. This will automatically download and install all the required plugins or dependencies and will create a .terraform folder(hidden).
Now, you can run : terraform apply. This code will run your terraform code and will create the infrastructure. As you run this code, you have to type 'yes' a couple of times or even more. To get rid of this, you can run : terraform apply --auto-approve. This will automatically approve for any permissions asked during execution of the code. You will get a public IP after a message of successfull run of the code. Open it in browser and you can see the content that you uploaded on github in your browser through this public IP.

You can check your AWS WebUI. You will see the resources are created and the instances running

Don't forget to change the state of instances to 'stop' or 'terminate' or else other 750 Hrs., you will start getting charged.
------------------------------------------------------------------------------------------------------------------------------
And keep track of you billing too!
-
Enjoy :)
