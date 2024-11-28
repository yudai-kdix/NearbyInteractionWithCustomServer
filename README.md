# Nearby Interaction with Custom Server

This is a sample app demonstrating the use of the Nearby Interaction framework to measure the distance between two iPhones. A web API server hosted on Cloudflare is utilized for exchanging discovery tokens.

## System Requirements

- iOS 15.0 or later  
- iPhone 11 or later (excluding iPhone SE)

## How to Use

Prepare two iPhones and follow these steps:

1. Launch the app on one iPhone and tap the **Get My Code** button. If you see a message like "Your code: 1234," the process has succeeded.  
2. Launch the app on the other iPhone and tap the **Get My Code** button.  
3. On each iPhone, enter the four-digit code displayed on the other device into the **Peer Code** field.  
4. Tap the **Start** button on both iPhones.  
5. Move the iPhones closer together or farther apart. The **Distance** displayed at the bottom of the screen will update in real time. The distance is measured in meters.
