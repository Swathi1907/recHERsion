
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import serviceAccountJson from "./shield-service-account.json";
import type { ServiceAccount } from "firebase-admin";

const serviceAccount: ServiceAccount = {
  projectId: serviceAccountJson.project_id,
  clientEmail: serviceAccountJson.client_email,
  privateKey: serviceAccountJson.private_key,
};

const firebaseApp =
  getApps().length > 0
    ? getApps()[0]
    : initializeApp({
        credential: cert(serviceAccount),
        projectId: "shield-b855d",
      });

export const firebaseMessaging = getMessaging(firebaseApp);
