# NutriTrack iOS Native App

A comprehensive nutrition tracking iOS application built with SwiftUI and SwiftData that promotes dietary variety through intelligent ingredient tracking and smart dish recommendations.

## 🌟 Features

### 📱 Core Functionality
- **Ingredient Management**: Add, edit, search, and categorize food ingredients with nutritional information
- **Recipe Builder**: Create and manage dishes with multiple ingredients and cooking instructions
- **Consumption Tracking**: Log daily food consumption with date-based filtering
- **Smart Recommendations**: AI-powered recipe suggestions based on consumption history and ingredient freshness
- **Dietary Variety Tracking**: Promotes diverse nutrition through ingredient usage analytics

### 🎨 User Experience
- **Native iOS Design**: Built with SwiftUI for optimal performance and native feel
- **Multi-Platform Support**: iOS, macOS, iPadOS, and visionOS compatible
- **Intuitive Navigation**: Tab-based interface with clean, modern design
- **Real-time Sync**: Local SwiftData storage with API synchronization
- **Offline Capability**: Works offline with automatic sync when connected

## 🏗️ Technical Architecture

### **Technology Stack**
- **Platform**: iOS 26.0+ (requires iOS beta)
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Language**: Swift 5.0
- **Architecture**: MVVM with Observable objects
- **Network**: URLSession with async/await

### **Key Components**
```
NutritrackiOSNative/
├── NutritrackiOSNativeApp.swift    # App entry point with SwiftData container
├── ContentView.swift               # Main tab navigation and home dashboard
├── APIService.swift                # Complete API integration layer
├── Item.swift                      # SwiftData models (Ingredient, Dish, etc.)
├── IngredientsView.swift           # Ingredient management interface
├── DishesView.swift               # Recipe management interface
└── Assets.xcassets/               # App icons and visual assets
```

### **Data Models**
- **Ingredient**: Food items with nutritional information and categorization
- **Dish**: Recipes containing multiple ingredients with quantities and instructions
- **ConsumptionLog**: Daily consumption tracking with timestamps
- **NutritionalInfo**: Detailed nutritional data (calories, protein, carbs, etc.)
- **Recommendation**: AI-generated recipe suggestions with freshness scoring

## 🚀 Getting Started

### **Prerequisites**
- Xcode 26.0 (Beta) or later
- iOS 26.0 Beta SDK
- macOS 15.5+ for development
- Valid Apple Developer account for device testing

### **Installation**
1. Clone the repository:
   ```bash
   git clone https://github.com/[username]/NutritrackiOSNative.git
   cd NutritrackiOSNative
   ```

2. Open the project in Xcode:
   ```bash
   open NutritrackiOSNative.xcodeproj
   ```

3. Select your development team in project settings
4. Choose your target device or simulator
5. Build and run the project (⌘+R)

### **API Configuration**
The app connects to a secure HTTPS API server:
- **Base URL**: `https://nutritrackapi.duckdns.org/api`
- **Authentication**: No authentication required for endpoints
- **Documentation**: See `API_DOCUMENTATION.md` for complete API specification

## 📚 Usage

### **Managing Ingredients**
1. Navigate to the **Ingredients** tab
2. Tap the **+** button to add new ingredients
3. Use the search bar and category filters to find existing ingredients
4. Edit or delete ingredients using the row actions

### **Creating Recipes**
1. Go to the **Dishes** tab
2. Tap **+** to create a new recipe
3. Add a name, description, and cooking instructions
4. Select ingredients and specify quantities
5. Save your recipe for future use

### **Tracking Consumption**
1. Open the **Track** tab
2. Select the date you want to log consumption for
3. Tap **+** to add a new consumption entry
4. Choose between logging an ingredient or a complete dish
5. Specify quantity and units

### **Getting Recommendations**
1. Visit the **Recommendations** tab
2. Adjust the analysis period (3, 7, 14, or 30 days)
3. View personalized recipe suggestions based on your consumption history
4. Each recommendation shows freshness score and reasoning

## 🛠️ Development

### **Build Commands**
```bash
# Build for iOS Simulator
xcodebuild -project NutritrackiOSNative.xcodeproj -scheme NutritrackiOSNative -sdk iphonesimulator

# Build for iOS Device
xcodebuild -project NutritrackiOSNative.xcodeproj -scheme NutritrackiOSNative -sdk iphoneos

# Run Tests
xcodebuild test -project NutritrackiOSNative.xcodeproj -scheme NutritrackiOSNative -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### **Project Structure**
- **Models**: SwiftData models for local persistence
- **Views**: SwiftUI views for each major feature
- **Services**: API integration and networking
- **Assets**: App icons, colors, and visual resources

## 🔒 Security

- **HTTPS Only**: All API communications use secure HTTPS
- **Data Privacy**: User data is stored locally and synchronized securely
- **No Authentication**: Current version doesn't require user accounts
- **App Transport Security**: Fully compliant with iOS security requirements

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

For support, questions, or feature requests:
- Open an issue on GitHub
- Check the API documentation in `API_DOCUMENTATION.md`
- Review the project documentation in `CLAUDE.md`

## 🎯 Roadmap

- [ ] User authentication and profiles
- [ ] Advanced nutrition analytics
- [ ] Meal planning features
- [ ] Social sharing capabilities
- [ ] Barcode scanning for ingredients
- [ ] Integration with health apps
- [ ] Dark mode support
- [ ] Accessibility improvements

---

**Built with ❤️ using SwiftUI and SwiftData**

*Promoting healthy eating through dietary variety tracking*