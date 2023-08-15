import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

songs = pd.read_excel("dataframes/final_songs.xlsx")
songs.shape
songs.describe()
print(songs.keys())


# EDA


sns.distplot(songs['track_popularity']).set_title('Track Popularity Distribution');

plt.subplots(figsize = (15,8))
sns.heatmap(songs.corr(), annot=True,cmap="PiYG")
plt.title("Correlations Among Features", fontsize = 18);

songs["track_popularity"].describe()

songs.loc[songs['track_popularity'] < 24, 'track_popularity'] = 0
songs.loc[songs['track_popularity'] >= 24, 'track_popularity'] = 1

print("popular\t\t{}".format(sum(songs["track_popularity"] == 1)))
print("not popular\t{}".format(sum(songs["track_popularity"] == 0)))

# Modeling
from sklearn import metrics
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.tree import DecisionTreeClassifier
from xgboost import XGBClassifier
from sklearn.metrics import make_scorer, accuracy_score, roc_auc_score 
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import train_test_split

songs.columns
features = ["acousticness", "danceability", "energy", "key", "duration_ms", "time_signature",
            "instrumentalness", "liveness", "mode", "speechiness", 
            "tempo", "valence", "artist_popularity", "artist_followers"]

training = songs.sample(frac = 0.8,random_state = 420)
X_train = training[features]
y_train = training["track_popularity"]
X_test = songs.drop(training.index)[features]

X_train, X_valid, y_train, y_valid = train_test_split(
    X_train, y_train, test_size = 0.2, random_state = 420
)

## Logistic Regression
LR_Model = LogisticRegression()
LR_Model.fit(X_train, y_train)
LR_Predict = LR_Model.predict(X_valid)
LR_Accuracy = accuracy_score(y_valid, LR_Predict)
print("Accuracy: " + str(LR_Accuracy))

LR_AUC = roc_auc_score(y_valid, LR_Predict) 
print("AUC: " + str(LR_AUC))

LR_confusion = metrics.confusion_matrix(y_valid, LR_Predict)
LR_cm = metrics.ConfusionMatrixDisplay(confusion_matrix = LR_confusion)

LR_cm.plot()
plt.show()

## Random Forest Classifier
RFC_Model = RandomForestClassifier()
RFC_Model.fit(X_train, y_train)
RFC_Predict = RFC_Model.predict(X_valid)
RFC_Accuracy = accuracy_score(y_valid, RFC_Predict)
print("Accuracy: " + str(RFC_Accuracy))

RFC_AUC = roc_auc_score(y_valid, RFC_Predict) 
print("AUC: " + str(RFC_AUC))

RFC_confusion = metrics.confusion_matrix(y_valid, RFC_Predict)
RFC_cm = metrics.ConfusionMatrixDisplay(confusion_matrix = RFC_confusion)

RFC_cm.plot()
plt.show()

## K Nearest Neighbors
KNN_Model = KNeighborsClassifier()
KNN_Model.fit(X_train, y_train)
KNN_Predict = KNN_Model.predict(X_valid)
KNN_Accuracy = accuracy_score(y_valid, KNN_Predict)
print("Accuracy: " + str(KNN_Accuracy))

KNN_AUC = roc_auc_score(y_valid, KNN_Predict) 
print("AUC: " + str(KNN_AUC))

KNN_confusion = metrics.confusion_matrix(y_valid, KNN_Predict)
KNN_cm = metrics.ConfusionMatrixDisplay(confusion_matrix = KNN_confusion)

KNN_cm.plot()
plt.show()

## Decision Tree
DT_Model = DecisionTreeClassifier()
DT_Model.fit(X_train, y_train)
DT_Predict = DT_Model.predict(X_valid)
DT_Accuracy = accuracy_score(y_valid, DT_Predict)
print("Accuracy: " + str(DT_Accuracy))

DT_AUC = roc_auc_score(y_valid, DT_Predict) 
print("AUC: " + str(DT_AUC))

DT_confusion = metrics.confusion_matrix(y_valid, DT_Predict)
DT_cm = metrics.ConfusionMatrixDisplay(confusion_matrix = DT_confusion)

DT_cm.plot()
plt.show()

## Extreme Gradient Boost
n = len(features)
XGB_Model = XGBClassifier(objective = "binary:logistic", n_estimators = n, seed = 123)
XGB_Model.fit(X_train, y_train)
XGB_Predict = XGB_Model.predict(X_valid)
XGB_Accuracy = accuracy_score(y_valid, XGB_Predict)
print("Accuracy: " + str(XGB_Accuracy))

XGB_AUC = roc_auc_score(y_valid, XGB_Predict) 
print("AUC: " + str(XGB_AUC))

XGB_confusion = metrics.confusion_matrix(y_valid, XGB_Predict)
XGB_cm = metrics.ConfusionMatrixDisplay(confusion_matrix = XGB_confusion)

XGB_cm.plot()
plt.show()

## Overall Comparison
model_performance = pd.DataFrame(
    {'Model': ['LogisticRegression', 
               'RandomForestClassifier', 
               'KNeighborsClassifier',
               'DecisionTreeClassifier',
               'XGBClassifier'],
    'Accuracy': [LR_Accuracy,
                 RFC_Accuracy,
                 KNN_Accuracy,
                 DT_Accuracy,
                 XGB_Accuracy],
    'AUC': [LR_AUC, RFC_AUC, KNN_AUC, DT_AUC, XGB_AUC]}
)

model_performance.sort_values(by = "Accuracy", ascending = False)

model_performance.sort_values(by = "AUC", ascending = False)

