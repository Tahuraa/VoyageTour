// Dev-mode stub: logs the email instead of sending it.
// Swap this out for nodemailer/SendGrid/etc. once SMTP credentials are available.
const sendEmail = async ({ to, subject, text }) => {
  console.log(`\n--- Email to ${to} ---\nSubject: ${subject}\n${text}\n----------------------\n`);
};

module.exports = sendEmail;
