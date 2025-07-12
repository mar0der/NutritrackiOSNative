# CLAUDE.md - KEEP IN CONTEXT
**Essential project configuration - Always load for token efficiency**

**⚠️ IMPORTANT INSTRUCTION FOR CLAUDE:**
- NEVER modify Parts 1-2 without explicit user permission
- Part 3 (Current Tasks) can be updated freely during development work
- When adding content, always respect this three-part structure

---

# PART 1: iOS DEVELOPMENT GUIDELINES
*Reusable guidelines for any iOS project*

## Apple Official Resources
**Accessible Documentation:**
- Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/ ✅
  - Clarity over brevity, UpperCamelCase types, lowerCamelCase everything else
  - "Write documentation comment for every declaration"

**Restricted Access (JavaScript/login required):**
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- SwiftUI Documentation: https://developer.apple.com/documentation/swiftui
- Swift Language Guide: https://docs.swift.org/swift-book/

## iOS 26 Key Features
- **Liquid Glass Design**: New material combining optical glass qualities with fluidity
- **WebView Integration**: Native web content embedding without UIKit
- **Rich Text Editing**: Enhanced TextView and AttributedString support
- **@Animatable Macro**: Easier view animations
- **Performance**: Automatic improvements for existing SwiftUI code

## Development Best Practices
- **Architecture**: MVVM pattern for SwiftUI apps
- **Data**: SwiftData for local storage, async/await for networking
- **Security**: JWT in Keychain (never UserDefaults), HTTPS-only
- **Testing**: Swift Testing framework (`@Test`) + XCTest for UI
- **Documentation**: Document every public declaration

---

# PART 2: PROJECT CONFIGURATION
*Nutritrack iOS App Specific Settings*

## Project Overview
Native iOS nutrition tracking app (SwiftUI + SwiftData) with MVVM architecture. Promotes dietary variety through intelligent ingredient tracking and smart dish recommendations.

**Project**: `NutritrackiOSNative.xcodeproj`, **Scheme**: `NutritrackiOSNative`
- API: https://api.nerdstips.com/v1 (JWT authentication)
- Server SSH: root@nerdstips.com (read-only access)
- URL Scheme: `nutritrack://` (Google OAuth)

## Server Infrastructure
**Docker Containers** (running on nerdstips.com):
- `nutritrack-web` (deployment-web) - Nginx reverse proxy :80,:443
- `nutritrack-api` (deployment-api) - Backend API :3001  
- `nutritrack-db` (postgres:16-alpine) - Database :5432

**Backend Location**: `/var/www/nutritrack/`
- Deployment configs: `/var/www/nutritrack/deployment/` (docker-compose.yml, .env, SSL setup)
- Backend code: `/var/www/nutritrack/backend/`
- API docs: `API_DOCUMENTATION.md`, `MOBILE_API_DOCUMENTATION.md`

## Tech Stack & Architecture
- **Platform**: iOS 26.0+, Swift 5.0, SwiftUI, SwiftData, Xcode 26.0+
- **Auth**: JWT in Keychain, Google OAuth (ASWebAuthenticationSession)
- **Integration**: HealthKit, multi-platform (iOS, macOS, iPadOS, visionOS)
- **Pattern**: MVVM with feature-based organization

## Project Structure
**Core**: `NutritrackiOSNativeApp.swift` (entry + SwiftData), `ContentView.swift` (tab nav)  
**Models**: `Ingredient`, `Dish`, `DishIngredient`, `ConsumptionLog`, `NutritionalInfo`  
**Services**: `APIService` (JWT auth), `AuthService` (Keychain), `GoogleOAuthService`, `HealthKitManager`  
**Views**: `Auth/`, `Home/`, `Ingredients/`, `Dishes/`, `Track/`, `Recommendations/`, `Common/`

## Development Patterns
- **API Integration**: JWT tokens in Keychain, automatic 401 handling, local-first SwiftData sync
- **Error Handling**: Custom types (`APIError`, `AuthError`) with localized descriptions
- **Logging**: Emoji prefixes (🔥, ❌, 📱)
- **Testing**: Located in `NutritrackiOSNativeTests/` and `NutritrackiOSNativeUITests/`

## Common Tasks
- **New API Endpoints**: Add models in `APIService.swift`, implement with auth
- **New Views**: Create in `Views/FeatureName/`, follow MVVM, use `CustomErrorAlert`
- **New Models**: Add to schema in `NutritrackiOSNativeApp.swift`
- **New Constants**: Add to `Utils/Constants.swift` with appropriate struct grouping

---

# PART 3: CURRENT TASKS & PROGRESS
*Dynamic section - updated during development*

## Active Tasks
*No active tasks currently tracked*

## Recent Completions
*Task history will appear here*

## Notes
*Development notes and discoveries will be logged here*