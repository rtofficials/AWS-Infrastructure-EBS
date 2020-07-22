provider "aws" {
	version = "~> 2.66"
	region     = "ap-south-1"
	profile    = "iam-user"
	access_key = "access-ID-here"
	secret_key = "Secret-ID-here"

}

/* == key pair == */
resource "tls_private_key" "archKeyPair" {
	algorithm   = "RSA"
}


resource "aws_key_pair" "archKey" {
	key_name   = "archKey"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClZErD3+lOy0Sat5e0fr0njb0ew5xRQbxcoHR9xhDVMl2GVEBRXjqFxfCLpwOrUOQy3GuD//LmxlCCzf+fb7gCHFH5Dlz01kHgzRFujNhPAW8tjtt1iLTplCthJdkWUVvFEKs51KpuIwAVDcSdBI3IZqf5+pkCXZ4YEefia+WT5oiwsDJIccc+DvzLXOkMo1UHhPHxOikXaDnD9xDQJogzseXTmRu+1o5Y5n9x3YgibZqKQVGq17Ex4MRwwSvL8eTHUAidG8i0st2Kw3rVCa032hZRMwzb8ji3KJVXjWVZ+J7xi6mxD1Gi779AjrlJn5W09SdPGTkwNZzlXgIIjtNcedFmFMEX7asVDnqFDUboHbVH+Vy6TS2LEsSOcJpUXHBYsX4OYj1lu2QRj67eCdsR9qp1pVMZikwAE0XJSBIiJbjVMU232Iai4PdvUWvs5i3seHMrCOSlpwMrkjsuAyIvTG9bCJvo5k0nX8Ep5lwgaUvcKiDOdya2BSgv4mNUQD0= silverhonk@armour"

	depends_on = [tls_private_key.archKeyPair]

}

/* == security group == */
resource "aws_security_group" "securityGroup" {
	depends_on  = [aws_key_pair.archKey]
  	name        = "securityGroup"
  	description = "SSH and HTTP"

  	ingress {
    	description = "HTTP"
    	from_port   = 80
    	to_port     = 80
    	protocol    = "tcp"
    	cidr_blocks = ["0.0.0.0/0"]
  	}

	ingress {
    	description = "SSH"
    	from_port   = 22
    	to_port     = 22
    	protocol    = "tcp"
  	  	cidr_blocks = ["0.0.0.0/0"]
  	}

  	egress {
    	from_port   = 0
    	to_port     = 0
    	protocol    = "-1"
    	cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
	name = "awssg"
  }
}


/* == instance == */
resource "aws_instance" "archInstance" {
	depends_on 	  = [aws_security_group.securityGroup,]
	ami           = "ami-0447a12f28fddb066"
	instance_type = "t2.micro"
	key_name      =  aws_key_pair.archKey.key_name
	security_groups = ["launch-wizard-1"]
	
	tags = {
		name = "archInstance"
	}

	provisioner "remote-exec" {
		inline = [
			"sudo pacman -S httpd  php git -y",
			"sudo systemctl restart httpd",
			"sudo systemctl enable httpd"
		]
	}

	connection {
		type = "ssh"
		user = "ec2-user"
		private_key = tls_private_key.archKeyPair.private_key_pem
		host     = aws_instance.archInstance.public_ip
	}

}


/* == EBS volume == */
resource "aws_volume_attachment" "ebs_attach" {
	device_name = "/dev/sda"
	volume_id   = aws_ebs_volume.kayjen-vol.id
	instance_id = aws_instance.archInstance.id
	force_detach = true
}

resource "aws_ebs_volume" "kayjen-vol" {
	availability_zone = aws_instance.archInstance.availability_zone
	size              = 1

	tags = {
    	name = "vol"
  	}
}

resource "null_resource" "remote-connection"  {
	depends_on = [aws_volume_attachment.ebs_attach]

	connection {
		type     = "ssh"
		user     = "ec2-user"
		private_key = tls_private_key.archKeyPair.private_key_pem
		host     = aws_instance.archInstance.public_ip
	}
	
// == Format the EBS--> Mount it-->Download Code from GitHub ==
provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvda",
      "sudo mount  /dev/xvda  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/rtofficials/LW-task.git /var/www/html/"
	  ]
	}
}

/* == S3 bucket == */
resource "aws_s3_bucket" "arch-bucket" {
	bucket = "arch-bucket"
	acl = "private"
    force_destroy = true
    versioning {
		enabled = true
	} 
}

/* == downloading from github and uploading in bucket == */
resource "null_resource" "cluster"  {
	depends_on = [aws_s3_bucket.kayjen-bucket]
	provisioner "local-exec" {
	command = "git clone https://github.com/rtofficials/LW-task.git"
  	}
}

resource "aws_s3_bucket_object" "bucky" {
	depends_on = [aws_s3_bucket.kayjen-bucket , null_resource.cluster]
	bucket = aws_s3_bucket.kayjen-bucket.id
    key = "page.png"    
	source = "LW-task/page.png"
    acl = "public-read"
}

output "image-content" {
  value = aws_s3_bucket_object.bucky
}

/* == cloufFront == */
resource "aws_cloudfront_distribution" "cfDistro" {
	depends_on = [aws_s3_bucket.kayjen-bucket , null_resource.cluster]
	origin {
		domain_name = aws_s3_bucket.kayjen-bucket.bucket_regional_domain_name
		origin_id   = "S3-kayjen-id"


		custom_origin_config {
			http_port = 80
			https_port = 80
			origin_protocol_policy = "match-viewer"
			origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
		}
	}
 
	enabled = true
  
	default_cache_behavior {
		allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods = ["GET", "HEAD"]
		target_origin_id = "S3-kayjen-id"
 
		forwarded_values {
			query_string = false
 
			cookies {
				forward = "none"
			}
		}
		viewer_protocol_policy = "allow-all"
		min_ttl = 0
		default_ttl = 3600
		max_ttl = 86400
	}
 
	restrictions {
		geo_restriction {
 
			restriction_type = "none"
		}
	}
 
	viewer_certificate {
		cloudfront_default_certificate = true
	}
}

resource "null_resource" "server"  {


depends_on = [null_resource.remote-connection]


	provisioner "local-exec" {
	    command = "start firefox ${aws_instance.archInstance.public_ip}"
  	}
}



output "domain-name" {
	value = aws_cloudfront_distribution.cfDistro.domain_name
}
