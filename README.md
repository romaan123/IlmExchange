# 📱 IlmExchange – Skill Barter & Micro Tutoring Platform  

IlmExchange is a **peer-to-peer mobile application** built with **Flutter, Firebase, and Dart** that enables users to **trade skills and micro-tutoring sessions without monetary transactions**.  
The app fosters a **community-driven learning ecosystem** by combining **skill discovery, scheduling, chat, ratings, and notifications** in a seamless mobile experience.  

## ✨ Features  

### 🔐 User Authentication  
- Email/password & Google Sign-In via Firebase Authentication  
- Password reset functionality  
- Secure session handling with authentication state monitoring  

### 👤 Onboarding & User Profiles  
- Personalized onboarding with animated screens  
- Profile management: name, bio, profile photo  
- Online status & last seen indicators  
- Skills offered/requested displayed on profile  
- Editable profile settings  

### 🛒 Skill Marketplace  
- Browse & search skills across categories  
- Post skill offers (to teach) or requests (to learn)  
- Filter by category, mode (online/in-person), experience level, duration  
- Dashboard for managing active offers & requests  

### 💬 Real-Time Chat & Communication  
- Firebase Firestore-based messaging  
- Presence indicators (online/offline, last seen)  
- Secure storage of conversations  

### 📅 Session Scheduling  
- Integrated calendar for tutoring sessions  
- Propose, accept, reschedule, or cancel sessions  
- Notifications for upcoming classes & changes  

### ⭐ Ratings & Reviews  
- Post-session feedback system  
- Average rating displayed on profiles for trust & credibility  

### 🔔 Notifications  
- Real-time push notifications with Firebase Cloud Messaging (FCM)  
- Alerts for session requests, messages, and reminders  

### 🔒 Security & Testing  
- Firestore database rules to ensure data privacy  
- Authentication/session management tested with helper utilities  

## 🛠️ Tech Stack  

- **Flutter (Dart)** – Cross-platform app development  
- **Firebase Authentication** – User login & secure sessions  
- **Firebase Firestore** – Real-time database for skills, chat, and scheduling  
- **Firebase Cloud Messaging (FCM)** – Push notifications  
- **Provider/Bloc** – State management (depending on implementation)  
- **Google Sign-In** – Social authentication
- 

## 🚀 Getting Started  

Follow these steps to set up the project locally.  

### Prerequisites  
- Install [Flutter](https://flutter.dev/docs/get-started/install)  
- Install [Git](https://git-scm.com/)  
- Create a Firebase project & enable Authentication, Firestore, and Cloud Messaging  

### Installation  

1. Clone the repository:  
   ```bash
   git clone https://github.com/<your-username>/IlmExchange.git
   cd IlmExchange
