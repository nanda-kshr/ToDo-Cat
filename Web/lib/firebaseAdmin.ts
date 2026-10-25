import { initializeApp, getApps, cert, ServiceAccount } from "firebase-admin/app";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import fs from "fs";
import path from "path";

if (!getApps().length) {
  try {
    let serviceAccount: ServiceAccount | undefined;

    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    } else {
      const localKeyPath = path.join(process.cwd(), "firebase-service-account.json");
      if (fs.existsSync(localKeyPath)) {
        const fileContent = fs.readFileSync(localKeyPath, "utf8");
        serviceAccount = JSON.parse(fileContent);
      }
    }

    if (serviceAccount) {
      initializeApp({
        credential: cert(serviceAccount),
      });
      console.log("[FirebaseAdmin] Successfully initialized");
    } else {
      console.warn("[FirebaseAdmin] No service account key found, push notifications disabled");
    }
  } catch (error) {
    console.error("[FirebaseAdmin] Initialization error:", error);
  }
}

export async function sendPushNotification(
  tokens: string[],
  payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }
) {
  if (!getApps().length || !tokens.length) {
    return { successCount: 0, failureCount: 0 };
  }

  try {
    const message: MulticastMessage = {
      tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          priority: "high",
          channelId: "todocat_reminders",
        },
      },
    };

    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast(message);
    return response;
  } catch (err) {
    console.error("[FirebaseAdmin] sendPushNotification error:", err);
    return { successCount: 0, failureCount: tokens.length };
  }
}
