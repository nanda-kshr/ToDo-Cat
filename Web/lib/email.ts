import nodemailer from "nodemailer";

function getTransporter() {
  const host = process.env.SMTP_HOST || "smtp.gmail.com";
  const port = parseInt(process.env.SMTP_PORT || "465", 10);
  const secure = process.env.SMTP_SECURE === "true" || port === 465;
  const user = process.env.SMTP_USER || process.env.SMTP_MAIL;
  const pass = (process.env.SMTP_PASS || "").replace(/\s+/g, "");

  if (!user || !pass) {
    console.warn("[Email] SMTP credentials not configured.");
    return null;
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: {
      user,
      pass,
    },
  });
}

function emailWrapper(content: string): string {
  const logoUrl = "https://todocat.instaroid.page/logo.png";

  return `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f9fafb; padding: 36px 16px; color: #374151;">
      <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px 28px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04); border: 1px solid #e5e7eb;">
        <div style="text-align: center; margin-bottom: 26px;">
          <img src="${logoUrl}" alt="TodoCat" width="56" height="45" style="display: block; margin: 0 auto 10px auto; border: 0; outline: none;" />
          <h1 style="font-size: 22px; font-weight: 800; color: #111827; margin: 0; letter-spacing: -0.3px;">TodoCat</h1>
        </div>
        ${content}
        <div style="margin-top: 32px; padding-top: 20px; border-top: 1px solid #f3f4f6; text-align: center; font-size: 12px; color: #9ca3af; line-height: 1.5;">
          TodoCat — Collaborative task management.
        </div>
      </div>
    </div>
  `;
}

export async function sendFriendRequestEmail({
  toEmail,
  senderName,
  senderEmail,
}: {
  toEmail: string;
  senderName?: string;
  senderEmail: string;
}) {
  const transporter = getTransporter();
  if (!transporter) return;

  const displayName = senderName && senderName.trim().length > 0 ? senderName : senderEmail;
  const fromAddress = process.env.SMTP_FROM || `"TodoCat" <${process.env.SMTP_MAIL || "noreply@todocat.app"}>`;

  const html = emailWrapper(`
    <h2 style="font-size: 18px; font-weight: 700; color: #1f2937; margin-bottom: 12px;">New Friend Request</h2>
    <p style="font-size: 14px; line-height: 1.6; color: #4b5563;">
      <strong>${displayName}</strong> (${senderEmail}) wants to be friends with you on TodoCat.
    </p>
    <p style="font-size: 14px; line-height: 1.6; color: #4b5563;">
      Once connected, you can share tasks with each other and complete them together.
    </p>
    <div style="text-align: center; margin: 26px 0;">
      <a href="https://todocat.instaroid.page" style="background-color: #374151; color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 12px; font-weight: 600; font-size: 14px; display: inline-block;">
        Open TodoCat
      </a>
    </div>
  `);

  try {
    await transporter.sendMail({
      from: fromAddress,
      to: toEmail,
      subject: `${displayName} sent you a friend request on TodoCat`,
      html,
    });
    console.log(`[Email] Friend request sent to ${toEmail}`);
  } catch (err) {
    console.error(`[Email] Failed to send friend request email:`, err);
  }
}

export async function sendFriendAcceptedEmail({
  toEmail,
  friendName,
  friendEmail,
}: {
  toEmail: string;
  friendName?: string;
  friendEmail: string;
}) {
  const transporter = getTransporter();
  if (!transporter) return;

  const displayName = friendName && friendName.trim().length > 0 ? friendName : friendEmail;
  const fromAddress = process.env.SMTP_FROM || `"TodoCat" <${process.env.SMTP_MAIL || "noreply@todocat.app"}>`;

  const html = emailWrapper(`
    <h2 style="font-size: 18px; font-weight: 700; color: #1f2937; margin-bottom: 12px;">Friend Request Accepted</h2>
    <p style="font-size: 14px; line-height: 1.6; color: #4b5563;">
      <strong>${displayName}</strong> accepted your friend request. You can now start sharing tasks and completing them together.
    </p>
    <div style="text-align: center; margin: 26px 0;">
      <a href="https://todocat.instaroid.page" style="background-color: #374151; color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 12px; font-weight: 600; font-size: 14px; display: inline-block;">
        View Friends on TodoCat
      </a>
    </div>
  `);

  try {
    await transporter.sendMail({
      from: fromAddress,
      to: toEmail,
      subject: `${displayName} accepted your friend request`,
      html,
    });
    console.log(`[Email] Friend accepted notification sent to ${toEmail}`);
  } catch (err) {
    console.error(`[Email] Failed to send friend accepted email:`, err);
  }
}

export async function sendSharedTaskEmail({
  toEmail,
  senderName,
  senderEmail,
  taskTitle,
}: {
  toEmail: string;
  senderName?: string;
  senderEmail: string;
  taskTitle: string;
}) {
  const transporter = getTransporter();
  if (!transporter) return;

  const displayName = senderName && senderName.trim().length > 0 ? senderName : senderEmail;
  const fromAddress = process.env.SMTP_FROM || `"TodoCat" <${process.env.SMTP_MAIL || "noreply@todocat.app"}>`;

  const html = emailWrapper(`
    <h2 style="font-size: 18px; font-weight: 700; color: #1f2937; margin-bottom: 12px;">New Shared Task</h2>
    <p style="font-size: 14px; line-height: 1.6; color: #4b5563;">
      <strong>${displayName}</strong> shared a task with you:
    </p>
    <div style="background-color: #f3f4f6; border-radius: 12px; padding: 14px 18px; margin: 18px 0; font-weight: 600; color: #111827; font-size: 15px;">
      ${taskTitle}
    </div>
    <p style="font-size: 13px; color: #6b7280; line-height: 1.5;">
      Remember: Both participants need to check this task as completed to finish it.
    </p>
    <div style="text-align: center; margin: 24px 0;">
      <a href="https://todocat.instaroid.page" style="background-color: #374151; color: #ffffff; text-decoration: none; padding: 12px 24px; border-radius: 12px; font-weight: 600; font-size: 14px; display: inline-block;">
        View Shared Task
      </a>
    </div>
  `);

  try {
    await transporter.sendMail({
      from: fromAddress,
      to: toEmail,
      subject: `${displayName} shared a task with you: "${taskTitle}"`,
      html,
    });
    console.log(`[Email] Shared task email sent to ${toEmail}`);
  } catch (err) {
    console.error(`[Email] Failed to send shared task email:`, err);
  }
}

export async function sendPasswordResetEmail({
  toEmail,
  userName,
  otp,
  resetLink,
}: {
  toEmail: string;
  userName?: string;
  otp: string;
  resetLink: string;
}) {
  const transporter = getTransporter();
  if (!transporter) return;

  const displayName = userName && userName.trim().length > 0 ? userName : toEmail.split("@")[0];
  const fromAddress = process.env.SMTP_FROM || `"TodoCat Security" <${process.env.SMTP_MAIL || "noreply@todocat.app"}>`;

  const html = emailWrapper(`
    <h2 style="font-size: 18px; font-weight: 700; color: #1f2937; margin-bottom: 12px;">Reset Your Password</h2>
    <p style="font-size: 14px; line-height: 1.6; color: #4b5563;">
      Hi <strong>${displayName}</strong>, we received a request to reset your TodoCat password.
    </p>

    <div style="background-color: #f3f4f6; border-radius: 16px; padding: 20px; margin: 20px 0; text-align: center; border: 1px dashed #d1d5db;">
      <div style="font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 1.5px; color: #6b7280; margin-bottom: 8px;">
        Your 6-Digit OTP Code
      </div>
      <div style="font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #111827; font-family: monospace;">
        ${otp}
      </div>
      <div style="font-size: 11px; color: #9ca3af; margin-top: 6px;">
        Expires in 15 minutes
      </div>
    </div>

    <p style="font-size: 14px; line-height: 1.6; color: #4b5563; text-align: center;">
      Or click the button below to reset your password directly in your browser:
    </p>

    <div style="text-align: center; margin: 24px 0;">
      <a href="${resetLink}" style="background-color: #111827; color: #ffffff; text-decoration: none; padding: 13px 28px; border-radius: 12px; font-weight: 700; font-size: 14px; display: inline-block;">
        Reset Password
      </a>
    </div>

    <p style="font-size: 12px; color: #9ca3af; line-height: 1.5; margin-top: 20px;">
      If you did not request this, you can safely ignore this email. Your password will remain unchanged.
    </p>
  `);

  try {
    await transporter.sendMail({
      from: fromAddress,
      to: toEmail,
      subject: `${otp} is your TodoCat password reset code`,
      html,
    });
    console.log(`[Email] Password reset sent to ${toEmail}`);
  } catch (err) {
    console.error(`[Email] Failed to send password reset email:`, err);
  }
}
