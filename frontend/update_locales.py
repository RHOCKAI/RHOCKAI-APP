import os
import json

locales = ['ar', 'de', 'en', 'es', 'fr', 'ja', 'pt']
base_dir = r"c:\Users\beino\Desktop\AI_POSTURE\frontend\lib\l10n"

new_keys = {
    "goPremiumTitle": "Go Premium",
    "goPremiumSubtitle": "Train smarter. See results faster.",
    "featureHistory": "Full workout history & trends",
    "featureAccuracy": "Rep-by-rep accuracy breakdown",
    "featureHeatmap": "Calendar heatmap & streak tracking",
    "featureAchievements": "Complete achievement system",
    "featureVoice": "Voice coaching in 7 languages",
    "featureSupport": "Priority support",
    "weeklyPlanTitle": "Weekly",
    "weeklyPlanPriceText": "$2.99/week",
    "weeklyPlanLabel": "Most flexible",
    "monthlyPlanTitle": "Monthly",
    "monthlyPlanPriceText": "$4.99/month",
    "yearlyPlanTitle": "Yearly",
    "yearlyPlanPriceText": "$29.99/year",
    "yearlyPlanBadge": "Best Value · Save 50%",
    "lifetimePlanTitle": "Lifetime",
    "lifetimePlanPriceText": "$79.99 once",
    "lifetimePlanLabel": "🔒 Founding member price — limited",
    "startFreeTrial": "Start Free Trial",
    "freeTrialBadge": "3 DAYS FREE",
    "cancelAnytime": "Cancel anytime · No commitment",
    "restorePurchases": "Restore purchases",
    "maybeLater": "Maybe later"
}

for loc in locales:
    filepath = os.path.join(base_dir, f"app_{loc}.arb")
    if not os.path.exists(filepath):
        continue
    
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for k, v in new_keys.items():
        if k not in data:
            data[k] = v
            
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Updated arb files.")
