const argv = require('yargs').argv;
const controller = require('./lib/controller');


const main = async (config) => {


    const controller_ip = config.controller.public_ip;
    const ssh_key = config.ssh_key;

    let cont = new controller({
        host: controller_ip,
        username: 'ubuntu',
        key: ssh_key,
    });

    await cont.connect();
    await cont.deploy();
    await cont.installLicense();

};

const config = {
    controller : {
        public_ip: argv.host
    },
    ssh_key: 'C:\\Users\\boiangiu\\OneDrive - F5 Networks\\SE\\SSH Keys\\sorin_key.pem' || argv.key
};

main(config).
    then(() => {
        process.exit();
    }).
    catch((err) => {
        console.log('ERROR',err);
        process.exit();
    });