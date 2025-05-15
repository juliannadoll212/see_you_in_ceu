@echo off
echo Deploying Firebase Storage and Firestore Rules...
echo.

echo Deploying Firebase Storage Rules...
firebase storage:rules:release --rules=firebase_storage_rules.txt

echo.
echo Deploying Firestore Rules...
firebase firestore:rules:release --rules=firestore.rules

echo.
echo Rules deployment complete!
pause 