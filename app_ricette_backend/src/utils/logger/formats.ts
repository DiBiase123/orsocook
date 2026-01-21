import { format } from 'winston';

export const consoleFormat = format.combine(
  format.timestamp({ format: 'HH:mm:ss' }),
  format.colorize(),
  format.printf((info) => {
    return `${info.timestamp} [${info.level}] ${info.message}`;
  })
);

export const fileFormat = format.combine(
  format.timestamp(),
  format.json()
);

export const apiFormat = format.printf((info) => {
  return `${info.timestamp} [API] ${info.message}`;
});
