# configManager.py
import os
import json

configPath = os.path.expanduser("~/.config/kdlm/config.json")

def loadConfig():
    if not os.path.exists(configPath):
        os.makedirs(os.path.dirname(configPath), exist_ok=True)
        defaultConfig = {
            "reopenOnClose": True,
            "showLaunchButton": True,
            "watchFolders": True,
            "autoProjectThumbnails": True,
<<<<<<< HEAD
            "sortBy": "modified",
=======
>>>>>>> 427cfb9 (initial)
            "projectPaths": [],
            "indexedFolders": [],
            "launchHistory": []
        }
        saveConfig(defaultConfig)
        return defaultConfig

    try:
        with open(configPath, 'r') as f:
            configData = json.load(f)

<<<<<<< HEAD
            # Safety checks for backwards compatibility (existing config files)
=======
>>>>>>> 427cfb9 (initial)
            if "indexedFolders" not in configData:
                configData["indexedFolders"] = []
            if "projectPaths" not in configData:
                configData["projectPaths"] = []
            if "launchHistory" not in configData:
                configData["launchHistory"] = []
            if "reopenOnClose" not in configData:
                configData["reopenOnClose"] = True
            if "showLaunchButton" not in configData:
                configData["showLaunchButton"] = True
            if "watchFolders" not in configData:
                configData["watchFolders"] = True
            if "autoProjectThumbnails" not in configData:
                configData["autoProjectThumbnails"] = True
<<<<<<< HEAD
            if "sortBy" not in configData:
                configData["sortBy"] = "modified"

=======
>>>>>>> 427cfb9 (initial)
            saveConfig(configData)
            return configData
    except Exception:
        return {
            "reopenOnClose": True,
            "showLaunchButton": True,
            "watchFolders": True,
            "autoProjectThumbnails": True,
<<<<<<< HEAD
            "sortBy": "modified",
=======
>>>>>>> 427cfb9 (initial)
            "projectPaths": [],
            "indexedFolders": [],
            "launchHistory": []
        }
<<<<<<< HEAD

=======
>>>>>>> 427cfb9 (initial)
def saveConfig(configData):
    with open(configPath, 'w') as f:
        json.dump(configData, f, indent=4)
