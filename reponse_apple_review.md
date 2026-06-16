# Réponse à l'évaluation de l'App Store (App Store Review)

Voici une proposition de réponse à envoyer à l'équipe de validation d'Apple, ainsi que les étapes à suivre pour préparer la preuve vidéo qu'ils demandent.

## 1. Ce que vous (le développeur) devez préparer (Enregistrement vidéo)

Avant d'envoyer la réponse à Apple, vous devez enregistrer une vidéo de l'écran de votre iPhone (appareil physique obligatoire, pas un simulateur) pour leur prouver que l'application utilise bien l'audio en arrière-plan.

**Étapes pour la vidéo :**
1. Lancez l'enregistrement d'écran sur votre iPhone.
2. Ouvrez votre application **Pouls-Mobile**.
3. Connectez-vous si nécessaire et accédez à la fonctionnalité **Message** (Messagerie).
4. Lancez la lecture d'un message audio (ou d'un média audio) dans une conversation.
5. **Étape cruciale :** Pendant que l'audio est en cours de lecture, quittez l'application pour retourner sur l'écran d'accueil de l'iPhone (l'application passe en arrière-plan).
6. Montrez que le son continue de jouer alors que vous êtes sur l'écran d'accueil (on devrait entendre le son ou voir l'indicateur d'utilisation de l'audio en arrière-plan en haut de l'écran).
7. Arrêtez l'enregistrement.

**Important :** Joignez cette vidéo au champ « Notes » de la section « Informations sur l’évaluation de l’application » dans App Store Connect.

---

## 2. Message à envoyer à Apple (Centre de résolution)

Copiez-collez le message suivant dans votre réponse à Apple (dans le Centre de résolution de l'App Store Connect) :

### Version Française (à privilégier si vous communiquez en français)

Bonjour l'équipe de validation de l'App Store,

Merci pour votre retour concernant notre application. 

Nous confirmons que notre application nécessite bien l'utilisation de la clé `UIBackgroundModes` avec la valeur `audio` dans le fichier `Info.plist`. Cette autorisation est requise pour notre **fonctionnalité de messagerie**.

En effet, les utilisateurs peuvent s'échanger et écouter des messages vocaux/audio au sein de l'application. L'audio en arrière-plan permet à l'utilisateur de lancer la lecture d'un long message vocal, puis de réduire l'application (pour vérifier une autre application ou revenir à l'écran d'accueil) sans que la lecture audio ne s'interrompe.

Comme demandé, nous avons joint une vidéo (enregistrement d'écran depuis un appareil physique) dans la section "Notes" (Informations sur l’évaluation de l’application).

**Voici les étapes pour reproduire et tester cette fonctionnalité :**
1. Ouvrez l'application et connectez-vous à un compte.
2. ajouter un enfant a suivre (Une fois connecter, vous avez la possibilité d'ajouter un enfant a votre tabeleau de bord et le suivre
matricule : 24037789S
Ecole de ce enfant : Collège privé Hînneh Biabou
)
3. Accédez au menu plus dans la barre de navigation en bas.
4. cliquer sur le menu message
5. choisisr un enfant, 
6. Ouvrez une conversation de ce enfant.
7. Lancez la lecture du message audio en maintenant appuyer sur le bouton play.
8. relacher le bouton a la fin du vocal
9. une fois le vocal terminé, vous pouvez l'envoyer en cliquant sur le bouton envoyer, ou le supprimer en cliquant sur le bouton supprimer.



Nous espérons que ces informations et la vidéo jointe clarifient l'utilisation de cette permission. N'hésitez pas si vous avez besoin de plus de détails.

Cordialement,
L'équipe de développement.

### Version Anglaise (recommandée, car les évaluateurs sont souvent anglophones)

Hello App Store Review Team,

Thank you for your feedback regarding our application.

We would like to clarify that our app does indeed require the `UIBackgroundModes` key with the `audio` value in the `Info.plist`. This background mode is essential for our **messaging feature**.

Users can send and listen to audio/voice messages within the app chats. The background audio feature allows users to start playing an audio message and then background the app (go to the home screen or switch to another app) without the audio playback stopping abruptly.

As requested, we have attached a screen recording demonstrating this functionality on a physical device. You can find this video in the "App Review Information" Notes section.

**Steps to reproduce and test this feature:**
1. Launch the app and log into an account.
2. Navigate to the Messages section.
3. Open a conversation that contains an audio message.
4. Tap play on the audio message.
5. While the audio is playing, swipe up to return to the iOS Home Screen (background the app).
6. Notice that the audio message continues to play seamlessly in the background.

We hope this clarifies the necessity of the background audio capability for our app's user experience. Please let us know if you need any further information.

Best regards,
The Development Team.
