'use strict';
const { createLogger, format, transports } = require('winston');

const logger = (data = {}) => {
    const ip = data.ip || '';
    const type = data.type || '';
    const debugLevel= data.level || 'info';
    return createLogger({
        level: debugLevel,
        format: format.combine(
            format.align(),
            format.colorize(),
            format.timestamp({
                format: 'HH:mm:ss'
            }),
            format.printf(info => `${info.timestamp} ${ip} ${type} ${info.level}: ${info.message}`)
        ),
        transports: [new transports.Console()]
    });
};

module.exports = logger;