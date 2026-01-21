// app_ricette_backend/src/services/email.service.ts
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export class EmailService {
  private transporter: nodemailer.Transporter;
  private fromEmail: string;
  private frontendUrl: string;

  constructor() {
    // Configurazione SMTP da variabili d'ambiente
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = parseInt(process.env.SMTP_PORT || '587');
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const smtpSecure = process.env.SMTP_SECURE === 'true';

    // Validazione configurazione
    if (!smtpHost || !smtpUser || !smtpPass) {
      console.warn('⚠️  Configurazione SMTP incompleta. Email non saranno inviate.');
      console.warn('   Imposta: SMTP_HOST, SMTP_USER, SMTP_PASS');
    }

    this.fromEmail = process.env.SMTP_FROM || `"OrsoCook" <${smtpUser}>`;
    this.frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';

    // Creazione transporter
    this.transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpSecure,
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
      // Timeout per evitare blocchi
      connectionTimeout: 10000, // 10 secondi
      greetingTimeout: 10000,
      socketTimeout: 10000,
    });

    // Verifica connessione SMTP (solo in sviluppo)
    if (process.env.NODE_ENV === 'development') {
      this.verifyConnection();
    }
  }

  /**
   * Verifica la connessione al server SMTP
   */
  private async verifyConnection(): Promise<void> {
    try {
      await this.transporter.verify();
      console.log('✅ Connessione SMTP verificata con successo');
    } catch (error) {
      console.error('❌ Errore verifica connessione SMTP:', error);
      console.warn('⚠️  Email non saranno inviate fino alla risoluzione');
    }
  }

  /**
   * Invia email di verifica account
   */
  async sendVerificationEmail(email: string, token: string, username: string): Promise<boolean> {
const verificationUrl = `https://orsocook.vercel.app/api/auth/verify-email/${token}`;    
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verifica Account OrsoCook</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #7E69AB; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; border: 1px solid #e0e0e0; border-top: none; }
            .button { display: inline-block; background-color: #7E69AB; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
            .code { font-family: monospace; background-color: #f0f0f0; padding: 10px; border-radius: 4px; margin: 10px 0; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>🎉 Benvenuto in OrsoCook!</h1>
          </div>
          <div class="content">
            <h2>Ciao ${username}!</h2>
            <p>Grazie per esserti registrato su <strong>OrsoCook</strong>, la tua community di ricette preferita.</p>
            <p>Per completare la registrazione e iniziare a utilizzare tutte le funzionalità, verifica il tuo indirizzo email cliccando sul pulsante qui sotto:</p>
            
            <div style="text-align: center;">
              <a href="${verificationUrl}" class="button">🔓 Verifica Account</a>
            </div>
            
            <p>Se il pulsante non funziona, copia e incolla questo link nel tuo browser:</p>
            <div class="code">${verificationUrl}</div>
            
            <p><strong>⚠️ Importante:</strong> Questo link scadrà tra <strong>24 ore</strong>.</p>
            
            <p>Se non ti sei registrato su OrsoCook, ignora semplicemente questa email.</p>
            
            <p>A presto,<br>Il team di OrsoCook 🐻👨‍🍳</p>
          </div>
          <div class="footer">
            <p>OrsoCook - La tua community di ricette preferita</p>
            <p>© ${new Date().getFullYear()} OrsoCook. Tutti i diritti riservati.</p>
          </div>
        </body>
      </html>
    `;

    const text = `
      Benvenuto in OrsoCook!
      
      Ciao ${username},
      
      Grazie per esserti registrato su OrsoCook, la tua community di ricette preferita.
      
      Per completare la registrazione, verifica il tuo indirizzo email cliccando sul link qui sotto:
      
      ${verificationUrl}
      
      Il link scadrà tra 24 ore.
      
      Se non ti sei registrato su OrsoCook, ignora semplicemente questa email.
      
      A presto,
      Il team di OrsoCook
    `;

    return this.sendEmail({
      to: email,
      subject: '🎉 Verifica il tuo account OrsoCook',
      html,
      text,
    });
  }

  /**
   * Invia email per reset password
   */
  async sendPasswordResetEmail(email: string, token: string, username: string): Promise<boolean> {
    const resetUrl = `${this.frontendUrl}/reset-password?token=${token}`;
    
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Reset Password OrsoCook</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #E65100; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; border: 1px solid #e0e0e0; border-top: none; }
            .button { display: inline-block; background-color: #E65100; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
            .warning { background-color: #FFF3E0; border-left: 4px solid #E65100; padding: 10px; margin: 15px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>🔐 Reset Password OrsoCook</h1>
          </div>
          <div class="content">
            <h2>Ciao ${username}!</h2>
            <p>Abbiamo ricevuto una richiesta per reimpostare la password del tuo account <strong>OrsoCook</strong>.</p>
            
            <div style="text-align: center;">
              <a href="${resetUrl}" class="button">🔑 Reimposta Password</a>
            </div>
            
            <div class="warning">
              <p><strong>⚠️ Attenzione:</strong> Se non hai richiesto il reset della password, ignora questa email. Il tuo account è al sicuro.</p>
            </div>
            
            <p>Il link di reset scadrà tra <strong>1 ora</strong> per motivi di sicurezza.</p>
            
            <p>Se il pulsante non funziona, copia e incolla questo URL nel tuo browser:</p>
            <div style="background-color: #f0f0f0; padding: 10px; border-radius: 4px; margin: 10px 0; font-family: monospace; word-break: break-all;">
              ${resetUrl}
            </div>
            
            <p>Buona cucina! 🐻👨‍🍳</p>
          </div>
          <div class="footer">
            <p>OrsoCook - La tua community di ricette preferita</p>
            <p>© ${new Date().getFullYear()} OrsoCook. Tutti i diritti riservati.</p>
          </div>
        </body>
      </html>
    `;

    const text = `
      Reset Password OrsoCook
      
      Ciao ${username},
      
      Abbiamo ricevuto una richiesta per reimpostare la password del tuo account OrsoCook.
      
      Clicca sul link qui sotto per reimpostare la tua password:
      
      ${resetUrl}
      
      Attenzione: Se non hai richiesto il reset della password, ignora questa email.
      Il link di reset scadrà tra 1 ora per motivi di sicurezza.
      
      Buona cucina!
      Il team di OrsoCook
    `;

    return this.sendEmail({
      to: email,
      subject: '🔐 Reimposta la tua password OrsoCook',
      html,
      text,
    });
  }

  /**
   * Metodo generico per inviare email
   */
  async sendEmail(options: EmailOptions): Promise<boolean> {
    // Se SMTP non configurato, logga e ritorna successo fittizio in sviluppo
    if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
      console.warn('📧 Email non inviata (SMTP non configurato):', {
        to: options.to,
        subject: options.subject,
      });
      
      if (process.env.NODE_ENV === 'development') {
        console.log('📧 Contenuto email (sviluppo):');
        console.log('To:', options.to);
        console.log('Subject:', options.subject);
        console.log('Text:', options.text);
        console.log('---');
      }
      
      return true; // In sviluppo, fingiamo che l'email sia stata inviata
    }

    try {
      const mailOptions = {
        from: this.fromEmail,
        to: options.to,
        subject: options.subject,
        html: options.html,
        text: options.text || options.html.replace(/<[^>]*>/g, ''),
      };

      const info = await this.transporter.sendMail(mailOptions);
      
      console.log('📧 Email inviata con successo:', {
        to: options.to,
        subject: options.subject,
        messageId: info.messageId,
      });
      
      return true;
    } catch (error) {
      console.error('❌ Errore invio email:', {
        to: options.to,
        subject: options.subject,
        error: error instanceof Error ? error.message : error,
      });
      return false;
    }
  }
}

// Esporta un'istanza singleton
export const emailService = new EmailService();
