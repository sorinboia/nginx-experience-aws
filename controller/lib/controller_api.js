process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;

const fs = require('fs');
const axios = require('axios');


class ControllerApi {

    constructor({ host, username, password }) {
        this.username = username;
        this.password = password;
        this.base_url = `https://${host}/api/v1`;
    }

    async login() {
        const result = await axios.post(`${this.base_url}/platform/login`,{
            credentials: {
                type: "BASIC",
                username: this.username,
                password: this.password
            }
        });


        const session_cookie = result.headers['set-cookie'][0].split(';')[0].split('=')[1];
        this.session_cookie = session_cookie;
        this.axios = axios.create({
            baseURL:this.base_url,
            headers: {
                'Cookie':`session=${this.session_cookie};`
            }
        });
    }

    //CURRENTLY NOT WORKING, DON'T KNOW WHAT IS THE FORMAT OF THE LICENSE FILE THE API ACCEPTS
    async upload_license(lic) {
        if (!this.session_cookie) await this.login();
        await this.axios.post('/platform/license-file',{
            content:fs.readFileSync(lic).toString('base64')
        });
    }

    async getApiKey() {
        // No exposed endpoint to get the key yet
    }

    async configEnvironment({name,config= {}}) {
        if (!this.session_cookie) await this.login();

        await this.axios.put(`/services/environments/${name}`, {
            "metadata": {
                "name": `${name}`,
                "displayName": "",
                "description": "",
                "tags": []
            },
            "desiredState": {}
        });



    }

    async configCert({envN ,name ,config}) {
        if (!this.session_cookie) await this.login();

        await this.axios.put(`/services/environments/${envN}/certs/${name}`,{
            metadata: {
                name: name
            },
            desiredState: config
        })
    }

    async configGateway({envN ,name ,config}) {
        if (!this.session_cookie) await this.login();

        await this.axios.put(`/services/environments/${envN}/gateways/${name}`,{
            metadata:{
                name: name
            },
            desiredState: config
        })
    }

    async configApp({envN ,name ,config}) {
        if (!this.session_cookie) await this.login();

        await this.axios.put(`/services/environments/${envN}/apps/${name}`,{
            metadata:{
                name: name
            },
            desiredState: config
        })
    }

    async configComp({envN , appN, name ,config}) {
        if (!this.session_cookie) await this.login();

        await this.axios.put(`/services/environments/${envN}/apps/${appN}/components/${name}`,{
            metadata:{
                name: name
            },
            desiredState: config
        })
    }
}

module.exports = ControllerApi;