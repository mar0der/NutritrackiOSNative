# HealthKit Setup Instructions

## 📱 Required Xcode Project Configuration

### 1. Enable HealthKit Capability

1. Open **NutritrackiOSNative.xcodeproj** in Xcode
2. Select the **NutritrackiOSNative** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **HealthKit**

### 2. Add Privacy Usage Descriptions

Since this project uses the modern approach without a separate Info.plist file, add these entries in **Project Settings**:

1. Go to **NutritrackiOSNative** target
2. Select **Info** tab
3. Click **+** to add new entries:

**Required Entries:**

```
Key: NSHealthShareUsageDescription
Type: String
Value: NutriTrack reads your health profile (height, weight, age, gender) to calculate personalized nutrition goals and reads existing nutrition data to provide comprehensive dietary analysis and recommendations.

Key: NSHealthUpdateUsageDescription
Type: String
Value: NutriTrack saves your detailed meal and nutrient consumption to the Health app, creating a complete nutrition record that integrates with your overall health data and can be shared with healthcare providers.
```

### 3. Import Required Framework

The HealthKit framework is already imported in the HealthKitManager.swift file.

## 🎯 User Experience Flow

### Phase 1: Core Setup (App Launch)
- **Trigger**: First app launch or when user taps "Connect to Health"
- **Permissions**: Basic profile + core nutrition data
- **Benefits**: BMR calculation, basic macro tracking

### Phase 2: Enhanced Tracking (After 2 weeks)
- **Trigger**: Automatic suggestion after consistent usage
- **Permissions**: Detailed fats + essential vitamins
- **Benefits**: Heart health insights, immune system tracking

### Phase 3: Comprehensive Analysis (After 1 month)
- **Trigger**: Automatic suggestion for advanced users
- **Permissions**: B vitamins + essential minerals
- **Benefits**: Complete micronutrient analysis

## 🔧 Integration Points

1. **Home Screen**: HealthIntegrationCard shows connection status
2. **Track Screen**: Automatically syncs logged nutrition to HealthKit
3. **Settings**: Manual permission management
4. **Onboarding**: Optional HealthKit setup during first launch

## 📊 Data Synchronization

The app will:
- ✅ Read existing health profile to set personalized goals
- ✅ Write nutrition data as user logs meals
- ✅ Respect user's privacy choices and permission levels
- ✅ Work offline and sync when connected

## 🔒 Privacy & Security

- All data stays on device unless user explicitly shares
- User can revoke permissions anytime via Health app
- No authentication required - uses iOS HealthKit security
- Complies with Apple's health data guidelines