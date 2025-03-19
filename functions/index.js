const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// 🔹 Setup Gmail SMTP
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "atharvnikam778@gmail.com",  // Replace with your Gmail
    pass: "cxse yfry fpcw uavc",    // Replace with your App Password 

  },
});

// 🔹 Generate OTP Function
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// 🔹 Cloud Function to Send OTP
exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const otp = generateOTP();

  // 🔹 Store OTP in Firestore with timestamp
  await admin.firestore().collection("otps").doc(email).set({
    otp: otp,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 🔹 Email Message
  const mailOptions = {
    from: "your-email@gmail.com",
    to: email,
    subject: "Your Login OTP",
    text: `Your OTP for login is ${otp}. It will expire in 5 minutes.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error(error);
    return { success: false, error: error.message };
  }
});

// 🔹 Cloud Function to Verify OTP
exports.verifyOtp = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const enteredOtp = data.otp;

  const otpDoc = await admin.firestore().collection("otps").doc(email).get();

  if (!otpDoc.exists) return { success: false, error: "OTP not found." };

  const storedOtp = otpDoc.data().otp;
  if (enteredOtp === storedOtp) {
    await admin.firestore().collection("otps").doc(email).delete();  // Delete OTP after use
    return { success: true };
  } else {
    return { success: false, error: "Invalid OTP." };
  }
});
