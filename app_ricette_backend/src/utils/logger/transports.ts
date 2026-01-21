import { transports } from 'winston';

export const consoleTransport = new transports.Console({
  format: consoleFormat,
});

export const getFileTransports = () => [];
