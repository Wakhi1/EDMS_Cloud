const morgan = require('morgan');
const logger = require('../config/logger');
const stream = { write: (message) => logger.info(message.trim(), { type: 'http_access' }) };
module.exports = morgan(':remote-addr :method :url :status :res[content-length]B - :response-time ms', { stream });
