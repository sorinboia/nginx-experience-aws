resource "aws_iam_role" "web_iam_role" {
  name               = "web_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "iam_nginx_profile" {
  name = "web_instance_profile"
  role = "web_iam_role"
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
  name   = "web_iam_role_policy"
  role   = aws_iam_role.web_iam_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::sorinnginx"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::sorinnginx/*"]
    }
  ]
}
EOF
}







resource "aws_instance" "controller" {
  ami                  = "ami-09356619876445425"
  iam_instance_profile = aws_iam_instance_profile.iam_nginx_profile.id
  instance_type        = "t2.2xlarge"
  root_block_device {
    volume_size = "80"
  }
  associate_public_ip_address = true
  availability_zone           = var.aws_az
  subnet_id                   = aws_subnet.public-subnet.id
  security_groups             = [aws_security_group.sgweb.id]
  vpc_security_group_ids      = [aws_security_group.sgweb.id]
  key_name                    = var.key_name

  user_data = <<-EOF
      #!/bin/bash
      apt-get update
      swapoff -a
      ufw disable
      apt-get install awscli jq -y
      aws s3 cp s3://sorinnginx/controller-installer-3.4.0.tar.gz /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      echo $HOME > oldh.txt
      export HOME=/home/ubuntu
      echo $HOME > newh.txt
      /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname sorin --admin-lastname sorin --admin-email s@s.com --admin-password sorin2019 --self-signed-cert --auto-install-docker --tsdb-volume-type local
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "s@s.com","password": "sorin2019"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLTAxMUI3NzhGM0E1QkIxQTEyMjMzMkE1NjdFQUIwMjUyIgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLTAxMUI3NzhGM0E1QkIxQTEyMjMzMkE1NjdFQUIwMjUyCld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNQzB4TVMweE1WUXhORG8wTURvd01pNHhOekUwTnpCYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURFNU5EY3NJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpU1RBd01EQTVOVGcxT1NJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0ltbHVkR1Z5Ym1Gc0lpd2cKQ2lBZ0lDQWdJQ0FnSW5abGNuTnBiMjRpT2lBeENpQWdJQ0I5TENBS0lDQWdJSHNLSUNBZ0lDQWdJQ0FpWlhod2FYSjVJam9nSWpJdwpNakF0TVRFdE1URlVNVFE2TkRBNk1ESXVNVGN4TnpVeFdpSXNJQW9nSUNBZ0lDQWdJQ0pzYVcxcGRITWlPaUF5TUN3Z0NpQWdJQ0FnCklDQWdJbkJ5YjJSMVkzUWlPaUFpVGtkSlRsZ2dRMjl1ZEhKdmJHeGxjaUJCVUVrZ1RXRnVZV2RsYldWdWRDSXNJQW9nSUNBZ0lDQWcKSUNKelpYSnBZV3dpT2lBeE9UUTNMQ0FLSUNBZ0lDQWdJQ0FpYzNWaWMyTnlhWEIwYVc5dUlqb2dJa2t3TURBd09UVTROVGtpTENBSwpJQ0FnSUNBZ0lDQWlkSGx3WlNJNklDSnBiblJsY201aGJDSXNJQW9nSUNBZ0lDQWdJQ0oyWlhKemFXOXVJam9nTVFvZ0lDQWdmUXBkCgotLS0tLS0wMTFCNzc4RjNBNUJCMUExMjIzMzJBNTY3RUFCMDI1MgpDb250ZW50LVR5cGU6IGFwcGxpY2F0aW9uL3gtcGtjczctc2lnbmF0dXJlOyBuYW1lPSJzbWltZS5wN3MiCkNvbnRlbnQtVHJhbnNmZXItRW5jb2Rpbmc6IGJhc2U2NApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0ic21pbWUucDdzIgoKTUlJRnZBWUpLb1pJaHZjTkFRY0NvSUlGclRDQ0Jha0NBUUV4RHpBTkJnbGdoa2dCWlFNRUFnRUZBREFMQmdrcQpoa2lHOXcwQkJ3R2dnZ016TUlJREx6Q0NBaGVnQXdJQkFnSUpBSU16cFhRSHBTeWFNQTBHQ1NxR1NJYjNEUUVCCkN3VUFNQzR4RWpBUUJnTlZCQW9NQ1U1SFNVNVlJRWx1WXpFWU1CWUdBMVVFQXd3UFEyOXVkSEp2Ykd4bGNpQkQKUVNBeE1CNFhEVEU0TURVeE1URXlNVE0xTVZvWERUSXlNRFV4TURFeU1UTTFNVm93TGpFU01CQUdBMVVFQ2d3SgpUa2RKVGxnZ1NXNWpNUmd3RmdZRFZRUUREQTlEYjI1MGNtOXNiR1Z5SUVOQklERXdnZ0VpTUEwR0NTcUdTSWIzCkRRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFJWY1JHMW5XS1QyTy9zcnI2WWZzTWc3RUN5cEdocmgzckRzRmQKRXVwSzVRZFE3TVIvM0hrYjk0RFk4eDlMY0lkNVVjZnFXMVpZdXN4Z1pGTmx4OW9wbVlmaW5maXNXaHFyZXVZSgpNanBVTzZILzUvL1lRNk5sV05LQUdDMmp6NkxsR0QrVzAyakFTM2RHUGMzRXlOL2FnN3lVc1hKbUpldkVUK3UwCnFsUXI0QXBZanZnV1N2NG1pV0JjamYxbTEzczVGVDBhdWwrMUVJekhRWEtqK2xhR0xITUtzYUZ0MUdoL3EweVoKaEtNeXJpcFlMRGpHUWVNUW9zeDVsYUFBZ0o3TjNMbnhRbnpSaUE2Q3Q5QkZib3AvMEY3VDZ2NjRBcUJQR240Qgptem9sQ3Zlc1lnaWsranVDRGxNT0ZNbFV4cnFTejFBdlFlUHM4Z1lxb2FBcnRTY1RBZ01CQUFHalVEQk9NQjBHCkExVWREZ1FXQkJRU2FXR21XcXNtTXNzeFdwK1hqbHprd3luOFhUQWZCZ05WSFNNRUdEQVdnQlFTYVdHbVdxc20KTXNzeFdwK1hqbHprd3luOFhUQU1CZ05WSFJNRUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDcAo3emFEMU52TTFEVEVQemtDTm84QjBtUDhkMTRLdWV5YVlwVi9td01La0Frc2xMdnB3MTlqLzl3Wng4Rm0yWkZOClROQlRSYi9tcEh0Zk5QQ1BKWTEzY21lUUo2R1BNQTV4bGcvSUx3SWJzTzdsSno0bEZsWFlhTWpoKytHdkVPL2sKWEVsL05VRnROcW1yYjRzelhKMlNoYnIySjFoMHpURm5rMncxWDNwVnBpazJWTmpKZjd1VDZ0NVROWldwREhGdApLVzRhZkl4d0U1dXNVcUs4REF3YnJLazFGQit4S01XTnBUS1gxeXM2TitGZmVVeWM2SHVaM0pGVzNCNlhNMys5Ckw5cmVKbGkyVFFrYm9pQk1QSXFLZFJGVFovbGRhNHR3TW5pREVGOVlkTTd6QnR6VmZ4VGlmN1F5YndpZ3cvUDEKaFRJRlFpaTNQSWpLdkNyZHdGQmZNWUlDVFRDQ0Fra0NBUUV3T3pBdU1SSXdFQVlEVlFRS0RBbE9SMGxPV0NCSgpibU14R0RBV0JnTlZCQU1NRDBOdmJuUnliMnhzWlhJZ1EwRWdNUUlKQUlNenBYUUhwU3lhTUEwR0NXQ0dTQUZsCkF3UUNBUVVBb0lIa01CZ0dDU3FHU0liM0RRRUpBekVMQmdrcWhraUc5dzBCQndFd0hBWUpLb1pJaHZjTkFRa0YKTVE4WERUSXdNRFV4TWpFME5ERXdNRm93THdZSktvWklodmNOQVFrRU1TSUVJSnNqM0RpUWNTYVh4Sjd3Q29EZAp2bVFBa2xqOFhFRzlFLzBkeFVQbHRhU1JNSGtHQ1NxR1NJYjNEUUVKRHpGc01Hb3dDd1lKWUlaSUFXVURCQUVxCk1Bc0dDV0NHU0FGbEF3UUJGakFMQmdsZ2hrZ0JaUU1FQVFJd0NnWUlLb1pJaHZjTkF3Y3dEZ1lJS29aSWh2Y04KQXdJQ0FnQ0FNQTBHQ0NxR1NJYjNEUU1DQWdGQU1BY0dCU3NPQXdJSE1BMEdDQ3FHU0liM0RRTUNBZ0VvTUEwRwpDU3FHU0liM0RRRUJBUVVBQklJQkFIMXZudnZETEdVQUM4bGk1YzFsWnBGSGNRVTllcWlPOXZwTFhxSWJxd2JQCnd5dktqKzJtY0x2SGQ3VDQyNUh6OUVQZ01uUVNwNHFUZHBJaXVoeFl0N0ZTUTRkMGUyU1YzeHRma3B5eXlrV2YKUnBwSFI0WVozWG5VcEIxRGhFeXNJM2hMWm5PcllhM21uWkc5NWJwS28vT2VGM0c3Zk5tLzltRkJ2S1VrdXQ5awpQb3FvaWIzaTEzZTlQMTJDaVUvekNGbWNIYlRLclQxb2J5MWcwcGlPa1oxckVMRVF1U2FkVE5nbHQ4V0hBRzRXCk1DdHh4cS85citIOGZyaFVtOTc5S2RVeHc2ancvY2srZnRoNm1qaVc4dUFlRU1JRWlqekpUQ2llb0wwdE9wYWkKcURoUitqZ3JxL3l1dUtLdnNJdEhoQTI5cnlRR3FEKzhUcGF3eWZUYWJKWT0KCi0tLS0tLTAxMUI3NzhGM0E1QkIxQTEyMjMzMkE1NjdFQUIwMjUyLS0KCg=="}'
    EOF

  tags = {
    Name = "controller"
  }
}