import winston from 'winston';
const { transports } = winston;
import { consoleFormat } from './formats';

export const consoleTransport = new transports.Console({
  format: consoleFormat,
});

export const getFileTransports = () => [];