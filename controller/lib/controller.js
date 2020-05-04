"use strict";


const Ubuntu_server = require('./ubuntu_server');
const controllerApi = require('./controller_api');

const cUser = 's@s.com';
const cPassword = 'sorin2019';

//const controllerFile = '6controller-installer-3.3.0.tar.gz';
const controllerFile = 'offline-6controller-installer-1701324.tar.gz';




class controller extends Ubuntu_server {

    constructor (data) {
        super({...data,type:'Controller',debugLevel: 'debug'});
        this.cApi = new controllerApi({
            host: this.host,
            username: cUser,
            password: cPassword
        });



        this.controllerCommands = [
            `sudo su -c "hostnamectl set-hostname ${this.host}"`,
            'sudo apt-get update',
            'swapoff -a',
            'sudo ufw disable',
            `sudo echo "127.0.0.1 ${this.host}" | sudo tee -a /etc/hosts`,
            'sudo sudo apt-get install awscli jq -y',
            `aws s3 cp s3://sorinnginx/${controllerFile} ${controllerFile}`
        ];

        this.controllerShellCommands =[
            `tar zxvf ${controllerFile}\n`,
            'cd 6controller-installer\n',
            'host_ip=$(ip addr show eth0 | grep "inet\\b" | awk \'{print $2}\' | cut -d/ -f1)\n',
            `./install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn ${this.host} --organization-name nginx1 --admin-firstname sorin --admin-lastname sorin --admin-email ${cUser} --admin-password ${cPassword} --self-signed-cert --auto-install-docker --tsdb-volume-type local\n`
        ];
    }

    async deploy()  {

        this.logger.info('delpoyment started');
        //await this.ssh.putDirectory('components/6controller/uploads_controller', 'uploads_controller');
        // Above original bellow will need to be changed

        await this.ssh.putDirectory('C:\\Users\\boiangiu\\Desktop\\Nginx Demo\\nodejs\\components\\6controller\\uploads_controller', 'uploads_controller');

        for (let i in this.controllerCommands) {
            let result = await this.ssh.execCommand(this.controllerCommands[i]);
        }
        let shell = await this.ssh.requestShell();
        const ubuntu_hostname = this.host.split('.')[0];
        await new Promise((res,rej) => {
            shell.on('data', (data) => {

                let stringData = data.toString().trim();
                this.logger.debug(stringData);
                if ( (stringData.indexOf((`ubuntu@${ubuntu_hostname}`)) === 0) || (stringData.indexOf((`root@${ubuntu_hostname}`)) === 0)) {

                    if(this.controllerShellCommands.length > 0) {
                        shell.write(this.controllerShellCommands.shift());
                    } else {
                        if (stringData.indexOf('OK, everything went just fine!')) {
                            res();
                        }
                    }
                }
            });
            shell.stderr.on('data', (data) => {
                this.logger.debug(data);
            });
        });

        this.logger.info('delpoyment finished');

    };

    async installLicense() {
        await this.cApi.login();

        // This will need to be changed
        await this.cApi.upload_license('C:\\Users\\boiangiu\\Desktop\\Nginx Demo\\nodejs\\components\\6controller\\uploads_controller\\controller_license.txt');


    }

    async getApiKey() {
        let key_command = await this.ssh.execCommand(`curl -k -X POST -H "Content-Type: application/json" -d \'{"email":"${cUser}","password":"${cPassword}"}\' https://localhost/sapi/auth/login/`);
        return JSON.parse(key_command.stdout).api_key;
    }
}

module.exports = controller;


