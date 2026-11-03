package za.co.reliefroute.reliefroute_backend.service;

import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;

@Service
public class SymptomService {

    private static final String DISCLAIMER =
            "This is general information, not medical advice. If symptoms last more than 3 days, "
                    + "get worse, or you are unsure, please ask a pharmacist or see a doctor.";

    // ---------------------------------------------------------------------------------
    // 1. What people might TYPE  ->  the standard symptom tag stored on medications.
    //    Add your own words here any time.
    // ---------------------------------------------------------------------------------
    private static final Map<String, String> SYNONYMS = new LinkedHashMap<>();

    private static void syn(String tag, String... phrases) {
        for (String p : phrases) {
            SYNONYMS.put(p, tag);
        }
        SYNONYMS.put(tag, tag);
    }

    static {
        syn("headache", "head ache", "head pain", "head hurts", "migraine");
        syn("fever", "high temperature", "temperature");
        syn("body aches", "body ache", "aches", "muscle pain", "sore muscles");
        syn("pain", "painful");
        syn("cold", "common cold");
        syn("flu", "influenza");
        syn("blocked nose", "stuffy nose", "congestion", "congested", "sinus");
        syn("runny nose");
        syn("sore throat", "scratchy throat");
        syn("allergy", "allergies", "allergic");
        syn("hay fever");
        syn("itching", "itch", "itchy");
        syn("sneezing", "sneeze");
        syn("hives");
        syn("stomach cramps", "cramps", "stomach pain", "stomach ache", "tummy ache", "tummy pain",
                "abdominal pain", "stomach spasms");
        syn("heartburn", "acid reflux", "indigestion");
        syn("diarrhoea", "diarrhea", "loose stool", "runny stomach");
        syn("tiredness", "tired", "fatigue", "low energy", "no energy");
        syn("vitamin deficiency", "low vitamins", "vitamins");
    }

    // ---------------------------------------------------------------------------------
    // 2. Medicine NAME (contains)  ->  category + symptom tags to store on the document.
    //    Used by the tagging endpoint. Add your own medicines here.
    // ---------------------------------------------------------------------------------
    private record Rule(String category, List<String> symptoms, boolean prescriptionOnly) {}

    private static final Map<String, Rule> RULES = new LinkedHashMap<>();

    static {
        List<String> allergy = List.of("allergy", "hay fever", "itching", "sneezing", "runny nose", "hives");
        RULES.put("allergex", new Rule("Allergy", allergy, false));
        RULES.put("clarityn", new Rule("Allergy", allergy, false));
        RULES.put("buscopan", new Rule("Stomach", List.of("stomach cramps"), false));
        RULES.put("corenza", new Rule("Cold & Flu",
                List.of("cold", "flu", "blocked nose", "runny nose", "sore throat", "fever", "headache", "body aches"), false));
        RULES.put("centrum", new Rule("Vitamins", List.of("vitamin deficiency", "tiredness"), false));
        RULES.put("panado", new Rule("Pain & Fever", List.of("headache", "fever", "pain", "body aches"), false));
        RULES.put("paracetamol", new Rule("Pain & Fever", List.of("headache", "fever", "pain", "body aches"), false));
        RULES.put("ibuprofen", new Rule("Pain & Fever", List.of("headache", "fever", "pain", "body aches"), false));
        RULES.put("nurofen", new Rule("Pain & Fever", List.of("headache", "fever", "pain", "body aches"), false));
        RULES.put("gaviscon", new Rule("Heartburn", List.of("heartburn"), false));
        RULES.put("rennie", new Rule("Heartburn", List.of("heartburn"), false));
        RULES.put("strepsils", new Rule("Throat", List.of("sore throat"), false));
        RULES.put("imodium", new Rule("Stomach", List.of("diarrhoea"), false));
        // Antibiotics: prescription-only, never suggested from a symptom search.
        RULES.put("amoxil", new Rule("Antibiotic", List.of("bacterial infection"), true));
        RULES.put("augmentin", new Rule("Antibiotic", List.of("bacterial infection"), true));
        RULES.put("cefalexin", new Rule("Antibiotic", List.of("bacterial infection"), true));
        RULES.put("ciprobay", new Rule("Antibiotic", List.of("bacterial infection"), true));
    }

    // Serious symptoms: don't suggest medicine, send them to urgent care instead.
    private static final Pattern EMERGENCY = Pattern.compile(
            "chest pain|can'?t breathe|cannot breathe|difficulty breathing|trouble breathing|"
                    + "short(ness)? of breath|severe bleeding|bleeding (a lot|heavily)|unconscious|passed out|"
                    + "seizure|stroke|swollen (face|tongue|throat)|vomiting blood|coughing (up )?blood|overdose|poison");
    private static final Pattern CRISIS = Pattern.compile(
            "suicid|kill myself|end my life|self[- ]?harm|hurt myself");

    private final FirestoreService db;
    private final ImageService images;

    public SymptomService(FirestoreService db, ImageService images) {
        this.db = db;
        this.images = images;
    }

    // All the standard symptoms (handy for a symptom picker in the app).
    public List<String> allSymptoms() {
        return new ArrayList<>(new TreeSet<>(SYNONYMS.values()));
    }

    // "I have a headache and a blocked nose" -> [headache, blocked nose]
    public List<String> detectSymptoms(String text) {
        String work = " " + text.toLowerCase(Locale.ROOT).replace('\u2019', '\'') + " ";
        List<Map.Entry<String, String>> entries = new ArrayList<>(SYNONYMS.entrySet());
        entries.sort((a, b) -> b.getKey().length() - a.getKey().length()); // longest phrases first
        Set<String> found = new LinkedHashSet<>();
        for (Map.Entry<String, String> e : entries) {
            Pattern p = Pattern.compile("\\b" + Pattern.quote(e.getKey()) + "\\b");
            if (p.matcher(work).find()) {
                found.add(e.getValue());
                work = p.matcher(work).replaceAll(" "); // so "stomach pain" doesn't also match "pain"
            }
        }
        return new ArrayList<>(found);
    }

    public Map<String, Object> search(String text) throws Exception {
        if (text == null || text.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tell us your symptoms, e.g. ?text=headache and fever");
        }
        String lower = text.toLowerCase(Locale.ROOT).replace('\u2019', '\'');
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("disclaimer", DISCLAIMER);

        if (CRISIS.matcher(lower).find()) {
            out.put("urgent", true);
            out.put("message", "It sounds like you're going through something really hard. You don't have to face it alone - "
                    + "please call the SADAG helpline on 0800 567 567 (free, South Africa) or 112 if you're in danger right now.");
            out.put("suggestions", List.of());
            return out;
        }
        if (EMERGENCY.matcher(lower).find()) {
            out.put("urgent", true);
            out.put("message", "These symptoms can be serious. Please call 10177 (ambulance) or 112 from a cellphone, "
                    + "or go to the nearest emergency room - don't wait for a delivery.");
            out.put("suggestions", List.of());
            return out;
        }

        out.put("urgent", false);
        List<String> symptoms = detectSymptoms(lower);
        out.put("matchedSymptoms", symptoms);
        if (symptoms.isEmpty()) {
            out.put("message", "We couldn't match that to a symptom we know. Try words like headache, fever, "
                    + "blocked nose, allergy or stomach cramps - or ask a pharmacist.");
            out.put("suggestions", List.of());
            return out;
        }

        List<Map<String, Object>> suggestions = new ArrayList<>();
        for (QueryDocumentSnapshot d : db.collectionRef("medications")
                .whereArrayContainsAny("symptoms", symptoms).get().get().getDocuments()) {
            Map<String, Object> med = db.toMap(d);
            if (Boolean.TRUE.equals(med.get("prescription_required"))) {
                continue; // never suggest prescription-only medicine from a symptom search
            }
            Object stock = med.get("stock_qty");
            if (stock instanceof Number n && n.doubleValue() <= 0) {
                continue;
            }
            List<String> matched = new ArrayList<>();
            if (med.get("symptoms") instanceof List<?> tags) {
                for (Object t : tags) {
                    if (symptoms.contains(String.valueOf(t))) {
                        matched.add(String.valueOf(t));
                    }
                }
            }
            med.put("matchedSymptoms", matched);
            images.addImageUrl(med);
            suggestions.add(med);
        }
        // best match first (most symptoms covered), then by name
        suggestions.sort((a, b) -> {
            int diff = ((List<?>) b.get("matchedSymptoms")).size() - ((List<?>) a.get("matchedSymptoms")).size();
            return diff != 0 ? diff : String.valueOf(a.get("name")).compareTo(String.valueOf(b.get("name")));
        });
        if (suggestions.size() > 10) {
            suggestions = new ArrayList<>(suggestions.subList(0, 10));
        }
        out.put("suggestions", suggestions);
        out.put("message", suggestions.isEmpty()
                ? "We don't have an over-the-counter medicine for that in our catalogue. Please ask a pharmacist or see a doctor."
                : "These are commonly used for the symptoms you listed.");
        return out;
    }

    /**
     * Adds "symptoms" + "category" to medications by matching the medicine name against RULES.
     * Skips medicines that already have symptoms unless overwrite=true.
     * Antibiotics are also marked prescription_required = true.
     */
    public Map<String, Object> tagMedications(boolean overwrite) throws Exception {
        int tagged = 0;
        int skipped = 0;
        List<String> noRule = new ArrayList<>();
        for (QueryDocumentSnapshot d : db.collectionRef("medications").get().get().getDocuments()) {
            Object existing = d.get("symptoms");
            if (!overwrite && existing instanceof List<?> l && !l.isEmpty()) {
                skipped++;
                continue;
            }
            Object rawName = d.get("name");
            String name = rawName == null ? "" : rawName.toString().toLowerCase(Locale.ROOT);
            Rule rule = null;
            for (Map.Entry<String, Rule> e : RULES.entrySet()) {
                if (name.contains(e.getKey())) {
                    rule = e.getValue();
                    break;
                }
            }
            if (rule == null) {
                noRule.add(rawName == null ? d.getId() : rawName.toString());
                continue;
            }
            Map<String, Object> update = new LinkedHashMap<>();
            update.put("symptoms", rule.symptoms());
            update.put("category", rule.category());
            if (rule.prescriptionOnly()) {
                update.put("prescription_required", true);
            }
            d.getReference().update(update).get();
            tagged++;
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("tagged", tagged);
        out.put("skippedAlreadyTagged", skipped);
        out.put("noRuleForThese", noRule);
        out.put("note", "For medicines in noRuleForThese, add a rule in SymptomService.RULES or set 'symptoms' by hand.");
        return out;
    }
}
