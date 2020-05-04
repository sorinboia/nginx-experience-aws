const loggerConstructor = require('./logger');
const node_ssh = require('node-ssh');

class Ubuntu_server {

    constructor ({host,username,password,key,type,debugLevel}) {
        this.host = host;
        this.username = username;
        this.password = password;
        this.key = key;
        this.ssh = new node_ssh();
        this.logger = loggerConstructor({ip:this.host,type,level:debugLevel});
    }

    async connect() {
        return await this.ssh.connect({
            host: this.host,
            username: this.username,
            privateKey: this.key
        }).then(()=> {
            this.logger.info('connected');
        });
    };

    async execCommand(cmd) {
        await this.ssh.execCommand(cmd);
    }
}


module.exports = Ubuntu_server;