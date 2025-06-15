import Foundation
import SwiftUI

// MARK: - Hero Origin Model
struct HeroOrigin: Codable, Identifiable {
    let id: UUID
    let heroClass: HeroClass
    let originStory: String
    let personalityTraits: [String]
    let homeland: MysticalHomeland
    let startingEquipment: [Item]
    let destinyProphecy: String
    let innerMotivation: String
    let secretPower: String
    let ancestralLineage: String
    let sacredOath: String
    
    init(heroClass: HeroClass, originStory: String, personalityTraits: [String],
         homeland: MysticalHomeland, startingEquipment: [Item], destinyProphecy: String,
         innerMotivation: String, secretPower: String, ancestralLineage: String, sacredOath: String) {
        self.id = UUID()
        self.heroClass = heroClass
        self.originStory = originStory
        self.personalityTraits = personalityTraits
        self.homeland = homeland
        self.startingEquipment = startingEquipment
        self.destinyProphecy = destinyProphecy
        self.innerMotivation = innerMotivation
        self.secretPower = secretPower
        self.ancestralLineage = ancestralLineage
        self.sacredOath = sacredOath
    }
    
    var epicIntroduction: String {
        return "\(originStory)\n\nFrom the \(homeland.name), you carry the \(ancestralLineage) and swear by the \(sacredOath). Your \(secretPower) shall aid you in fulfilling your destiny."
    }
}

// MARK: - Mystical Homeland
struct MysticalHomeland: Codable {
    let name: String
    let description: String
    let climate: String
    let magicalProperties: String
    let culturalTraditions: [String]
    let legendaryLandmarks: [String]
    let ancientSecrets: String
    let relationship: String // How the homeland shaped the hero
    
    var fullDescription: String {
        return "\(description) \(climate) \(magicalProperties) This land \(relationship)."
    }
}

// MARK: - Hero Origin Extensions
extension HeroOrigin {
    static func origin(for heroClass: HeroClass) -> HeroOrigin {
        switch heroClass {
        case .warrior:
            return HeroOrigin.warriorOrigin
        case .mage:
            return HeroOrigin.mageOrigin
        case .rogue:
            return HeroOrigin.rogueOrigin
        case .ranger:
            return HeroOrigin.rangerOrigin
        case .cleric:
            return HeroOrigin.clericOrigin
        }
    }
    
    // MARK: - Warrior Origin
    static var warriorOrigin: HeroOrigin {
        let homeland = MysticalHomeland(
            name: "Ironhold Peaks",
            description: "Towering mountains of black iron and gleaming steel, where the sound of hammers rings eternal and forges burn with unquenchable flame.",
            climate: "Harsh winds carry the scent of molten metal and the roar of dragon breath used to temper the finest weapons.",
            magicalProperties: "The mountains themselves are said to be the bones of an ancient titan, imbuing all who dwell here with unbreakable will and incredible strength.",
            culturalTraditions: ["The Ritual of First Blade", "Honor Duels at Dawn", "The Feast of Fallen Heroes", "Mountain-Song Battle Chants"],
            legendaryLandmarks: ["The Eternal Forge", "Titan's Backbone Ridge", "The Hall of Unbroken Oaths", "Dragonfire Crater"],
            ancientSecrets: "Hidden within the deepest mines lie weapons of the Titan-Kings, waiting for a warrior worthy to claim them.",
            relationship: "forged your spirit in the fires of adversity and taught you that true strength comes from protecting those who cannot protect themselves"
        )
        
        let startingEquipment = [
            Item(name: "Ironbound Gauntlets", type: .armor, level: 1, rarity: .common, 
                 effects: [ItemEffect(stat: .strength, amount: 2)]),
            Item(name: "Ancestor's Blade", type: .weapon, level: 1, rarity: .uncommon,
                 effects: [ItemEffect(stat: .strength, amount: 3), ItemEffect(stat: .xpGain, amount: 1)]),
            Item(name: "Titan's Tears", type: .potion, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .healthRegen, amount: 5)])
        ]
        
        return HeroOrigin(
            heroClass: .warrior,
            originStory: "Born beneath the shadow of the Eternal Forge, you were raised on tales of legendary warriors who stood against impossible odds. The mountain winds whispered of your destiny from the moment you first gripped a blade. Your mentor, a grizzled veteran of the Titan Wars, saw the fire in your eyes and knew that greatness flowed in your veins.",
            personalityTraits: ["Unwavering Courage", "Protective Instinct", "Honor-Bound", "Fierce Loyalty", "Indomitable Will"],
            homeland: homeland,
            startingEquipment: startingEquipment,
            destinyProphecy: "When darkness rises like a tide and hope seems but a flickering candle, the Child of Iron shall stand unmoved. With blade in hand and fire in heart, they shall be the shield that guards the innocent and the sword that cleaves through despair.",
            innerMotivation: "To prove that true strength lies not in conquering others, but in standing as an unbreakable wall between the innocent and those who would harm them.",
            secretPower: "Battle Fury of the Ancients - In moments of dire need, you can channel the spirits of fallen warriors, gaining their combined strength for a brief but crucial moment.",
            ancestralLineage: "blood of the Titan-Kings, the first warriors who carved civilization from chaos with steel and determination",
            sacredOath: "Iron Oath of Protection - 'By blade and blood, by steel and soul, I swear to guard the light against the darkness, to stand when others fall, and to never yield while breath remains in my body.'"
        )
    }
    
    // MARK: - Mage Origin
    static var mageOrigin: HeroOrigin {
        let homeland = MysticalHomeland(
            name: "Celestial Spires",
            description: "Floating towers of crystal and starlight that drift through the heavens, connected by bridges of pure magical energy.",
            climate: "The air shimmers with arcane power, and aurora-like phenomena dance constantly through skies that show glimpses of other dimensions.",
            magicalProperties: "Reality itself is more malleable here, allowing even novice mages to perform feats that would be impossible elsewhere.",
            culturalTraditions: ["The Ritual of First Spell", "Constellation Meditation", "Tome Binding Ceremonies", "The Great Convergence Festival"],
            legendaryLandmarks: ["The Infinite Library", "Observatory of Endless Skies", "The Nexus of All Magic", "Starfall Gardens"],
            ancientSecrets: "The towers hide spell formulae that predate creation itself, written in languages that reshape reality with each spoken syllable.",
            relationship: "opened your mind to the infinite possibilities of magic and taught you that knowledge is the greatest treasure of all"
        )
        
        let startingEquipment = [
            Item(name: "Novice's Starwoven Robes", type: .armor, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .intelligence, amount: 2)]),
            Item(name: "Crystal Focus Staff", type: .weapon, level: 1, rarity: .uncommon,
                 effects: [ItemEffect(stat: .intelligence, amount: 3), ItemEffect(stat: .xpGain, amount: 1)]),
            Item(name: "Essence of Pure Magic", type: .potion, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .intelligence, amount: 3)])
        ]
        
        return HeroOrigin(
            heroClass: .mage,
            originStory: "You first touched magic as a child when you accidentally opened a portal to the realm of living mathematics. Your natural affinity was so strong that reality itself seemed to bend around your untrained thoughts. The Archmages took you to the Celestial Spires, where you learned to harness the raw forces of creation through study, meditation, and the occasional spectacular magical accident.",
            personalityTraits: ["Insatiable Curiosity", "Analytical Mind", "Otherworldly Wisdom", "Creative Problem-Solver", "Respectful of Power"],
            homeland: homeland,
            startingEquipment: startingEquipment,
            destinyProphecy: "When the cosmic balance trembles and ancient magics run wild, the Star-Touched shall rise. With wisdom as their weapon and the cosmos as their canvas, they shall weave new realities and restore the harmony between all things.",
            innerMotivation: "To unlock the deepest mysteries of magic and use that knowledge to protect and improve the world, proving that power guided by wisdom can achieve the impossible.",
            secretPower: "Cosmic Resonance - You can temporarily align yourself with the fundamental forces of the universe, allowing you to cast spells far beyond your normal capabilities.",
            ancestralLineage: "spark of the First Mages, who spoke the words that separated light from darkness and gave form to the formless void",
            sacredOath: "Oath of Infinite Learning - 'By star and spell, by tome and tower, I swear to seek truth in all its forms, to use knowledge as a shield for the innocent, and to never let power corrupt the pursuit of wisdom.'"
        )
    }
    
    // MARK: - Rogue Origin
    static var rogueOrigin: HeroOrigin {
        let homeland = MysticalHomeland(
            name: "Shadowmere Districts",
            description: "A labyrinthine city where twilight reigns eternal, built in the spaces between dimensions where shadows have substance and secrets take physical form.",
            climate: "Perpetual dusk shrouds winding alleys and impossible architecture, where stairs lead up and down simultaneously and doors open to wherever you need them to go.",
            magicalProperties: "The boundary between hidden and revealed is paper-thin here, allowing masters of stealth to slip between realities like walking through doorways.",
            culturalTraditions: ["The Silent Initiation", "Dance of a Thousand Shadows", "The Great Heist Festival", "Whisper Network Gatherings"],
            legendaryLandmarks: ["The Impossible Bazaar", "Museum of Stolen Moments", "The Observatory of Hidden Truths", "Phantom Bridge Network"],
            ancientSecrets: "The city itself is alive, remembering every secret ever whispered within its walls, and it shares its knowledge with those who truly understand the art of remaining unseen.",
            relationship: "taught you that the greatest victories are won before the enemy realizes a battle has begun, and that information is more valuable than gold"
        )
        
        let startingEquipment = [
            Item(name: "Shadowsilk Cloak", type: .armor, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .agility, amount: 2)]),
            Item(name: "Whisper Blade", type: .weapon, level: 1, rarity: .uncommon,
                 effects: [ItemEffect(stat: .agility, amount: 3), ItemEffect(stat: .xpGain, amount: 1)]),
            Item(name: "Vial of Liquid Shadow", type: .potion, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .agility, amount: 3)])
        ]
        
        return HeroOrigin(
            heroClass: .rogue,
            originStory: "You were born in the moment between one heartbeat and the next, when shadows lengthen and secrets are born. The Shadow Guild found you walking through walls as a child, unaware that such things were supposed to be impossible. Under their tutelage, you learned that the greatest power comes not from strength or magic, but from being in the right place at precisely the right moment.",
            personalityTraits: ["Observant Nature", "Quick Thinking", "Mysterious Aura", "Pragmatic Approach", "Loyal to Few"],
            homeland: homeland,
            startingEquipment: startingEquipment,
            destinyProphecy: "When lies masquerade as truth and corruption hides behind noble facades, the Shadow-Walker shall emerge. Unseen and unheard, they shall be the blade that cuts through deception and the truth that dispels all illusions.",
            innerMotivation: "To use the darkness as a tool for justice, proving that sometimes the only way to preserve the light is to master the shadows that would consume it.",
            secretPower: "Phase Step - You can briefly exist between dimensions, allowing you to pass through solid objects and avoid any attack for a crucial moment.",
            ancestralLineage: "essence of the Void Dancers, the first beings to learn that emptiness and shadow were not absence, but potential waiting to be shaped",
            sacredOath: "Whispered Vow of the Hidden Path - 'By shadow and silence, by truth and twilight, I swear to be the blade in the darkness, the protector unseen, and the justice that comes when all other hope has failed.'"
        )
    }
    
    // MARK: - Ranger Origin
    static var rangerOrigin: HeroOrigin {
        let homeland = MysticalHomeland(
            name: "Evergreen Reaches",
            description: "An endless forest where every leaf holds ancient wisdom and the very air pulses with the heartbeat of nature itself.",
            climate: "Seasons flow like a gentle river, each bringing its own magic - spring's renewal, summer's abundance, autumn's wisdom, and winter's peaceful rest.",
            magicalProperties: "The forest is alive with consciousness, and those who listen carefully can hear the songs of every living thing harmonizing in perfect unity.",
            culturalTraditions: ["The Bonding with Beast Companions", "Seasonal Harmony Festivals", "The Great Migration Walks", "Star-Navigation Rituals"],
            legendaryLandmarks: ["The Heart Tree", "Singing Waterfalls", "Crystal Cave Networks", "The Aurora Grove"],
            ancientSecrets: "Deep in the forest's heart lies the First Seed, from which all life in the realm originally grew, still pulsing with creative power.",
            relationship: "taught you that all life is connected in an intricate web, and that protecting nature means protecting the future itself"
        )
        
        let startingEquipment = [
            Item(name: "Living Wood Bracers", type: .armor, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .agility, amount: 1), ItemEffect(stat: .intelligence, amount: 1)]),
            Item(name: "Heartwood Bow", type: .weapon, level: 1, rarity: .uncommon,
                 effects: [ItemEffect(stat: .agility, amount: 2), ItemEffect(stat: .intelligence, amount: 1), ItemEffect(stat: .xpGain, amount: 1)]),
            Item(name: "Nature's Blessing", type: .potion, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .healthRegen, amount: 3), ItemEffect(stat: .agility, amount: 2)])
        ]
        
        return HeroOrigin(
            heroClass: .ranger,
            originStory: "You were raised by the forest itself after being found as a child sleeping peacefully in a grove where flowers bloomed out of season. The ancient trees whispered your name on the wind, and woodland creatures served as your first teachers. You learned to speak the language of growing things and to understand that every step through the wilderness was a conversation with living history.",
            personalityTraits: ["Deep Connection to Nature", "Patient Wisdom", "Protective Instincts", "Keen Intuition", "Harmony Seeker"],
            homeland: homeland,
            startingEquipment: startingEquipment,
            destinyProphecy: "When the natural world cries out in pain and the balance of life itself hangs in peril, the Forest-Born shall answer. With beast as ally and nature as guide, they shall restore the harmony between civilization and the wild.",
            innerMotivation: "To protect the delicate balance between all living things, ensuring that the beauty and wisdom of the natural world survives for future generations to cherish.",
            secretPower: "Call of the Wild - You can temporarily commune with all the animals in a wide area, gaining their eyes, ears, and aid in times of great need.",
            ancestralLineage: "soul-bond with the First Forest, the primordial woodland that existed before time began and gave birth to all growing things",
            sacredOath: "Covenant of the Living World - 'By root and branch, by stone and stream, I swear to guard the balance of all things, to speak for those without voice, and to ensure that life in all its forms may flourish for all time.'"
        )
    }
    
    // MARK: - Cleric Origin
    static var clericOrigin: HeroOrigin {
        let homeland = MysticalHomeland(
            name: "Sanctum of Eternal Light",
            description: "A floating cathedral of pure radiance that exists simultaneously in the mortal realm and the celestial planes, where divine light takes solid form.",
            climate: "Warm, golden light suffuses everything, carrying the gentle power of hope and healing that soothes both body and soul.",
            magicalProperties: "Divine energy flows like water here, and prayers spoken in earnest have the power to reshape reality according to the highest good.",
            culturalTraditions: ["The Vigil of First Light", "Ceremonies of Healing Grace", "The Pilgrimage of Seven Virtues", "Dawn Chorus Gatherings"],
            legendaryLandmarks: ["The Altar of Infinite Compassion", "Gardens of Blessed Renewal", "The Spire of Answered Prayers", "Pools of Sacred Reflection"],
            ancientSecrets: "Within the cathedral's heart burns the Eternal Flame of Hope, said to contain the combined faith of every soul who has ever truly believed in goodness.",
            relationship: "filled your heart with unwavering compassion and taught you that the greatest strength comes from lifting others up"
        )
        
        let startingEquipment = [
            Item(name: "Blessed Vestments", type: .armor, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .intelligence, amount: 1), ItemEffect(stat: .healthRegen, amount: 1)]),
            Item(name: "Sacred Symbol of Light", type: .weapon, level: 1, rarity: .uncommon,
                 effects: [ItemEffect(stat: .intelligence, amount: 2), ItemEffect(stat: .healthRegen, amount: 2), ItemEffect(stat: .xpGain, amount: 1)]),
            Item(name: "Elixir of Divine Grace", type: .potion, level: 1, rarity: .common,
                 effects: [ItemEffect(stat: .healthRegen, amount: 5)])
        ]
        
        return HeroOrigin(
            heroClass: .cleric,
            originStory: "You were born during a solar eclipse when the barriers between mortal and divine were at their thinnest. Divine light surrounded you from your first breath, and you spoke your first words as a prayer for others' wellbeing. The Temple of Eternal Light recognized your calling immediately, raising you to understand that true power comes from serving others and that the greatest miracles spring from sincere compassion.",
            personalityTraits: ["Boundless Compassion", "Unwavering Faith", "Selfless Service", "Inner Strength", "Divine Wisdom"],
            homeland: homeland,
            startingEquipment: startingEquipment,
            destinyProphecy: "When darkness threatens to extinguish hope and despair seeks to claim all hearts, the Light-Bearer shall shine forth. With healing in their touch and prayers on their lips, they shall be the beacon that guides all souls home.",
            innerMotivation: "To be a conduit for divine compassion, healing not just physical wounds but the spiritual injuries that keep people from achieving their highest potential.",
            secretPower: "Divine Intervention - In moments of absolute crisis, you can call upon divine power to perform a miracle that defies all natural laws, but only when acting selflessly for others.",
            ancestralLineage: "blessing of the First Light, the original divine spark that brought hope into existence and still burns in the hearts of all who choose good over evil",
            sacredOath: "Sacred Vow of Endless Light - 'By hope and healing, by grace and goodness, I swear to be the light in darkness, the comfort in sorrow, and the strength for those who can no longer stand alone. Where there is pain, I bring peace. Where there is despair, I kindle hope.'"
        )
    }
}