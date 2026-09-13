/// SaHayak copy. Hindi + English. Emergency words stay short.
library;

class L {
  L(this.hi);
  final bool hi;

  String get tagline => "blood help nearby";
  String get email => hi ? "ईमेल" : "Your email";
  String get mobile => hi ? "मोबाइल" : "Your mobile";
  String get viaEmail => hi ? "ईमेल" : "Email";
  String get viaMobile => hi ? "मोबाइल" : "Mobile";
  String get otpHow => hi
      ? "ईमेल या मोबाइल। हम SMS नहीं पढ़ते।"
      : "Email or mobile. We never read SMS on your phone.";
  String get getCode => hi ? "कोड लें" : "Get a code";
  String get enterCode => hi ? "कोड लिखें" : "Enter the code";
  String get sendCode => hi ? "कोड भेजें" : "Send my code";
  String get six => hi ? "छह अंक" : "The six numbers";
  String get enter => hi ? "दाखिल हों" : "Enter";
  String get homeHint => hi ? "अभी आप कौन हैं?" : "Who are you right now?";
  String get need => hi ? "रक्त चाहिए" : "Need blood";
  String get needSub => hi ? "अस्पताल ने रक्त माँगा। पहले आपके भरोसे के लोग।" : "Hospital asked for blood. We start with people you trust.";
  String get donate => hi ? "मैं दे सकता/सकती हूँ" : "I can donate";
  String get donSub => hi ? "मैं दे सकता/सकती हूँ। फोन तब तक छिपा जब तक मैं कहूँ कि मैं जाऊँगा/जाऊँगी।" : "I can give. My phone stays hidden until I say I can go.";
  String get more => hi ? "और — आपात नहीं" : "More — extra help, not the emergency";
  String get locBodyDon => hi
      ? "सिर्फ़ यह कि पास किसे ज़रूरत है। पिन धुंधले जब तक आप ‘मैं जा सकता हूँ’ न दबाएँ।"
      : "We only show who needs you nearby. Pins stay fuzzy until you tap I can go.";
  String get locBody => hi
      ? "पास के मैचिंग लोग — तभी जब आप टैप करें। या शहर चुनें। पीछे से नहीं।"
      : "Nearby matching people — only after you tap. Or pick a city. We never follow you.";
  String get useGps => hi ? "लोकेशन दें" : "Use my location";
  String get cityInstead => hi ? "शहर चुनें" : "Use city instead";
  String get paste => hi ? "व्हाट्सऐप संदेश (वैकल्पिक)" : "Paste a WhatsApp message (optional)";
  String get fillForm => hi ? "फॉर्म भरें — अभी नहीं भेजा" : "Fill the form — not sent yet";
  String get send => hi ? "भेजें" : "Send";
  String get sendSub => hi ? "विश्वसनीय लोग पहले सुनें" : "trusted people hear first";
  String get home => hi ? "होम" : "Home";
  String get skipPings => hi ? "आज पिंग न करें (बुखार/व्रत)" : "Self-hold (skip pings)";
  String get available => hi ? "मैं उपलब्ध हूँ" : "I am available";
  String get iCanGo => hi ? "मैं जा सकता/सकती हूँ" : "I can go";
  String get phoneHidden => hi ? "फोन छिपा है" : "Phone hidden";
  String get hospital => hi ? "अस्पताल का नाम" : "Hospital name";
  String get slipLine => hi ? "कागज़ पर क्या लिखा है" : "What the paper says";
  String get slipFill => hi ? "पर्ची से भरें — अभी नहीं भेजा" : "Fill from the paper — not sent";
  String get familyGroups => hi ? "परिवार के ग्रुप" : "Family groups";
  
  // Enhanced features (new)
  String get nightMode => hi ? "रात का मोड" : "Night mode";
  String get bagProgress => hi ? "यूनिट की प्रगति" : "Unit progress";
  String get surgeonWaiting => hi ? "सर्जन का इंतज़ार" : "Surgeon waiting";
  String get fasting => hi ? "भूखा हूँ" : "Fasting";
  String get fever => hi ? "बुख़ार है" : "Have fever";
  String get donorHold => hi ? "आज की स्थिति" : "Today's status";
  String get restAndRecover => hi ? "आराम करो। ठीक हो जाने के बाद ही आएँ।" : "Rest and recover. Come back later.";
  String get noMorePings => hi ? "कोई भी पिंग नहीं" : "You won't be pinged";
  String get graceDate => hi ? "अगली दान की तारीख़" : "Next eligible day";
  String get lowBattery => hi ? "बैटरी कम है" : "Low battery";
  String get dataSaver => hi ? "डेटा सेवर चालू है" : "Data saver on";
  String get mapsOff => hi ? "मैप बंद। शहर सूची का उपयोग करें।" : "Maps off. Use city list.";
  String get deadButton => hi ? "अभी उपलब्ध नहीं है" : "Not available right now";
  String get womenFirst => hi ? "महिला पहले" : "Women first";
  String get sameEmergency => hi ? "दो फोन से एक ही आपात" : "Same emergency from two phones";
  String get prideHonesty => hi ? "हम ईमानदार हैं" : "Pride moment";
  String get needIntensity => hi ? "जरूरत का घनत्व" : "Need intensity";
  String get openRequests => hi ? "खुली रिक्वेस्ट" : "Open requests";
  String get noNames => hi ? "कोई नाम या फोन नहीं" : "No names or phones";
  String get walkToDoor => hi ? "इसी जगह जाइए" : "Go to this place";
  String get bloodBankDoor => hi ? "ब्लड बैंक का दरवाज़ा — बिस्तर पर नहीं" : "Blood bank door — not the bedside";
  String get phoneAfterAccept => hi ? "फोन स्वीकार के बाद ही" : "Phone only after you accepted";
    String get locTitle => hi ? "लोकेशन चुनें" : "Choose a location";
    String get delete => hi ? "खाता हटाएँ" : "Delete account";
}

