//
//  ContentView.swift
//  Memora Duel
//
//  Created by yunus emre yıldırım on 21.11.2025.
//


import SwiftUI
import Combine

// MARK: - 1. VERİ MODELLERİ VE SKIN SİSTEMİ

enum CardType {
    case question
    case answer
}

// --- YENİ: SKIN (GÖRÜNÜM) MODELİ ---
struct GameSkin: Identifiable, Equatable {
    let id: String
    let name: String
    let boardColor: AnyShapeStyle
    let cardBackPattern: AnyShapeStyle
    let accentColor: Color
    let iconName: String
    
    // Eşitlik kontrolü (Equatable protokolü için)
    static func == (lhs: GameSkin, rhs: GameSkin) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Tüm Skinlerin Listesi
    static let allSkins: [GameSkin] = [neonCyberSkin, magmaDragonSkin, forestSpiritSkin]
}

// Örnek Skinler
let neonCyberSkin = GameSkin(
    id: "cyber",
    name: "Neon Cyber",
    boardColor: AnyShapeStyle(LinearGradient(colors: [Color(hex: "0f172a"), Color(hex: "1e1b4b")], startPoint: .top, endPoint: .bottom)),
    cardBackPattern: AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)),
    accentColor: .cyan,
    iconName: "bolt.fill"
)

let magmaDragonSkin = GameSkin(
    id: "dragon",
    name: "Magma Dragon",
    boardColor: AnyShapeStyle(LinearGradient(colors: [Color(hex: "450a0a"), Color(hex: "7f1d1d")], startPoint: .top, endPoint: .bottom)),
    cardBackPattern: AnyShapeStyle(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)),
    accentColor: .orange,
    iconName: "flame.fill"
)

let forestSpiritSkin = GameSkin(
    id: "forest",
    name: "Forest Spirit",
    boardColor: AnyShapeStyle(LinearGradient(colors: [Color(hex: "052e16"), Color(hex: "14532d")], startPoint: .top, endPoint: .bottom)),
    cardBackPattern: AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)),
    accentColor: .green,
    iconName: "leaf.fill"
)

struct CardData: Identifiable {
    let id: Int
    let q: String
    let a: String
}

struct GameCard: Identifiable, Equatable {
    let id = UUID()
    let dataId: Int
    let text: String
    let type: CardType
    var isFaceUp: Bool = true
    var ownerSkin: GameSkin? = nil
    
    static func == (lhs: GameCard, rhs: GameCard) -> Bool {
        lhs.id == rhs.id
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
}

// --- VERİ SETLERİ ---
let englishDataSet = [
    CardData(id: 1, q: "Apple", a: "Elma"),
    CardData(id: 2, q: "Book", a: "Kitap"),
    CardData(id: 3, q: "Computer", a: "Bilgisayar"),
    CardData(id: 4, q: "Pencil", a: "Kalem"),
    CardData(id: 5, q: "Door", a: "Kapı"),
    CardData(id: 6, q: "Water", a: "Su"),
    CardData(id: 7, q: "Car", a: "Araba"),
    CardData(id: 8, q: "Window", a: "Pencere")
]

let mathDataSet = [
    CardData(id: 1, q: "2 + 2", a: "4"),
    CardData(id: 2, q: "5 x 3", a: "15"),
    CardData(id: 3, q: "12 / 4", a: "3"),
    CardData(id: 4, q: "100 - 1", a: "99"),
    CardData(id: 5, q: "3²", a: "9")
]

let geographyDataSet = [
    CardData(id: 1, q: "Türkiye", a: "Ankara"),
    CardData(id: 2, q: "Fransa", a: "Paris"),
    CardData(id: 3, q: "İngiltere", a: "Londra")
]

let cultureDataSet = [
    CardData(id: 1, q: "Demir", a: "Fe"),
    CardData(id: 2, q: "Su", a: "H2O")
]

// MARK: - 2. OYUN MOTORU (VIEW MODEL)

class GameViewModel: ObservableObject {
    @Published var screen: String = "menu"
    @Published var menuState: String = "mode_select" // mode_select, category_select, skin_select
    
    @Published var playerHealth: Int = 5
    @Published var opponentHealth: Int = 5
    @Published var playerHand: [GameCard] = []
    @Published var opponentHand: [GameCard] = []
    
    // Skin Ayarları
    @Published var playerSkin: GameSkin = neonCyberSkin // Oyuncunun seçtiği
    @Published var opponentSkin: GameSkin = magmaDragonSkin // Rakibin skini
    
    @Published var tableCard: GameCard? = nil
    @Published var resolutionCard: GameCard? = nil
    
    enum CardStatus { case normal, wrong, correct }
    @Published var tableCardStatus: CardStatus = .normal
    
    enum Turn { case player, opponent }
    @Published var turn: Turn = .opponent
    
    @Published var gameMessage: String = ""
    @Published var showTurnAlert: Bool = false
    @Published var shakeTable: Bool = false
    @Published var particles: [Particle] = []
    
    private var initialHealth = 5
    private let cardsPerGame = 8
    
    // Oyunu Başlat
    func startGame(dataSet: [CardData]) {
        let selectedData = Array(dataSet.shuffled().prefix(cardsPerGame))
        
        var pHand: [GameCard] = []
        var oHand: [GameCard] = []
        
        for item in selectedData {
            if Bool.random() {
                pHand.append(GameCard(dataId: item.id, text: item.q, type: .question, ownerSkin: playerSkin))
                oHand.append(GameCard(dataId: item.id, text: item.a, type: .answer, ownerSkin: opponentSkin))
            } else {
                pHand.append(GameCard(dataId: item.id, text: item.a, type: .answer, ownerSkin: playerSkin))
                oHand.append(GameCard(dataId: item.id, text: item.q, type: .question, ownerSkin: opponentSkin))
            }
        }
        
        playerHand = pHand.shuffled()
        opponentHand = oHand.shuffled()
        playerHealth = initialHealth
        opponentHealth = initialHealth
        tableCard = nil
        resolutionCard = nil
        tableCardStatus = .normal
        
        turn = .opponent
        gameMessage = "RAKİP BAŞLIYOR..."
        screen = "game"
        
        runAILogic()
    }
    
    // Yapay Zeka Döngüsü
    func runAILogic() {
        guard screen == "game" && turn == .opponent else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // 1. AI ATAK FAZI (Masa Boşsa)
            if self.tableCard == nil {
                if self.opponentHand.isEmpty { self.checkWinCondition(); return }
                
                let randomIndex = Int.random(in: 0..<self.opponentHand.count)
                let cardToPlay = self.opponentHand[randomIndex]
                
                withAnimation(.spring()) {
                    self.opponentHand.remove(at: randomIndex)
                    self.tableCard = cardToPlay
                    self.tableCardStatus = .normal
                    self.turn = .player
                    self.gameMessage = "SIRA SENDE! CEVABI BUL."
                }
                
                self.showTurnAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.showTurnAlert = false }
                
            } else {
                // 2. AI SAVUNMA FAZI (Masa Doluysa)
                self.gameMessage = "RAKİP DÜŞÜNÜYOR..."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let matchIndex = self.opponentHand.firstIndex(where: { $0.dataId == self.tableCard?.dataId }) {
                        if Double.random(in: 0...1) > 0.1 {
                            // Rakip bildi
                            let matchingCard = self.opponentHand[matchIndex]
                            withAnimation(.spring()) {
                                self.opponentHand.remove(at: matchIndex)
                                self.resolutionCard = matchingCard
                                self.gameMessage = "RAKİP CEVABI BULDU!"
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.triggerParticles(color: .red)
                                withAnimation {
                                    self.tableCard = nil
                                    self.resolutionCard = nil
                                    self.turn = .opponent
                                    self.gameMessage = "RAKİP SALDIRIYOR..."
                                }
                                if self.opponentHand.isEmpty { self.checkWinCondition() }
                                else { self.runAILogic() }
                            }
                        } else {
                            self.aiFail()
                        }
                    } else {
                        self.aiFail()
                    }
                }
            }
        }
    }
    
    func aiFail() {
        self.opponentHealth -= 1
        self.triggerParticles(color: .gray)
        withAnimation {
            self.tableCard = nil
            self.turn = .player
            self.gameMessage = "RAKİP BİLEMEDİ! FIRSAT SENDE."
        }
        
        self.showTurnAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.showTurnAlert = false }
        
        if self.opponentHealth <= 0 { self.checkWinCondition() }
    }
    
    // Oyuncu Hamlesi
    func playerPlayedCard(card: GameCard) {
        if tableCard == nil {
            if let index = playerHand.firstIndex(where: { $0.id == card.id }) {
                withAnimation { playerHand.remove(at: index) }
            }
            withAnimation(.spring()) {
                tableCard = card
                tableCardStatus = .normal
                turn = .opponent
                gameMessage = "HAMLENİ YAPTIN. RAKİP BEKLİYOR..."
            }
            triggerParticles(color: .blue)
            if playerHand.isEmpty { checkWinCondition() }
            else { runAILogic() }
        }
        else if let currentTableCard = tableCard {
            if card.dataId == currentTableCard.dataId {
                if let index = playerHand.firstIndex(where: { $0.id == card.id }) {
                    withAnimation { playerHand.remove(at: index) }
                }
                withAnimation(.spring()) {
                    self.resolutionCard = card
                }
                self.gameMessage = "HARİKA! DOĞRU CEVAP."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.triggerParticles(color: .yellow)
                    withAnimation {
                        self.tableCard = nil
                        self.resolutionCard = nil
                        self.turn = .player
                        self.gameMessage = "ŞİMDİ SALDIRI SIRASI SENDE."
                    }
                    self.showTurnAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.showTurnAlert = false }
                    
                    if self.playerHand.isEmpty { self.checkWinCondition() }
                }
                
            } else {
                if let index = playerHand.firstIndex(where: { $0.id == card.id }) {
                    withAnimation { playerHand.remove(at: index) }
                }
                withAnimation(.spring()) {
                    self.resolutionCard = card
                    self.tableCardStatus = .wrong
                }
                self.shakeTable = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.shakeTable = false }
                playerHealth -= 1
                self.gameMessage = "YANLIŞ! DOĞRUSU GELİYOR..."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut) {
                        self.resolutionCard = nil
                    }
                    if let correctIndex = self.playerHand.firstIndex(where: { $0.dataId == currentTableCard.dataId }) {
                        let correctCard = self.playerHand[correctIndex]
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring()) {
                                self.playerHand.remove(at: correctIndex)
                                self.resolutionCard = correctCard
                                self.tableCardStatus = .correct
                            }
                            self.triggerParticles(color: .green)
                            self.gameMessage = "İŞTE DOĞRU CEVAP!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    self.tableCard = nil
                                    self.resolutionCard = nil
                                    self.tableCardStatus = .normal
                                    self.turn = .opponent
                                    self.gameMessage = "SIRA RAKİBE GEÇTİ."
                                }
                                if self.playerHand.isEmpty { self.checkWinCondition() } else { self.runAILogic() }
                            }
                        }
                    } else {
                        self.turn = .opponent
                        self.runAILogic()
                    }
                }
                if playerHealth <= 0 { checkWinCondition() }
            }
        }
    }
    
    func checkWinCondition() { screen = "result" }
    
    func triggerParticles(color: Color) {
        for _ in 0..<20 {
            let p = Particle(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, color: color)
            particles.append(p)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.particles.removeAll() }
    }
    
    func goBackToModeSelect() { menuState = "mode_select" }
    func goBackToMenu() { screen = "menu"; menuState = "mode_select" }
}

// MARK: - 3. GÖRÜNÜMLER (VIEWS)

struct ContentView: View {
    @StateObject var vm = GameViewModel()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color(hex: "1e293b"), Color.black]), center: .center, startRadius: 2, endRadius: 650).ignoresSafeArea()
            if vm.screen == "menu" { MenuView(vm: vm) }
            else if vm.screen == "game" { GameView(vm: vm) }
            else if vm.screen == "result" { ResultView(vm: vm) }
        }.statusBar(hidden: true)
    }
}

// --- OYUN EKRANI ---
struct GameView: View {
    @ObservedObject var vm: GameViewModel
    @State private var draggingCard: GameCard?
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            ForEach(vm.particles) { p in ParticleView(particle: p) }
            
            if vm.showTurnAlert && vm.tableCardStatus != .wrong && vm.tableCardStatus != .correct {
                VStack {
                    Image(systemName: "sword.fill").font(.system(size: 50)).foregroundColor(.white)
                    Text("SIRA SENDE!").font(.largeTitle).bold().foregroundColor(.white)
                    Text("SALDIR VE KAZAN").font(.headline).foregroundColor(.blue)
                }.padding(40)
                .background(LinearGradient(colors: [.black, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(20)
                .shadow(color: .indigo.opacity(0.6), radius: 20, x: 0, y: 0)
                .transition(.scale.combined(with: .opacity)).zIndex(100)
                
            }
            
            VStack {
                // HUD
                HStack {
                    VStack(alignment: .leading) {
                        Text("RAKİP").font(.body).bold().foregroundColor(.gray)
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < vm.opponentHealth ? Color.red : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 16)
                            }
                        }
                    }
                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("SEN").font(.body).bold().foregroundColor(.gray)
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < vm.playerHealth ? .blue : .gray.opacity(0.3))
                                    .frame(width: 8, height: 16)
                            }
                        }
                    }
                }.padding()
                Text(vm.gameMessage).font(.caption).bold().padding(8).background(.ultraThinMaterial).cornerRadius(10).foregroundColor(vm.turn == .player ? .blue : .red)
                
                
                Spacer()
                
                // --- 3D MASA & SKIN TASARIMI ---
                ZStack {
                    // TAHTA ZEMİNİ (İKİYE BÖLÜNMÜŞ)
                    VStack(spacing: 0) {
                        // Üst Yarı: Rakip Skin
                        Rectangle()
                            .fill(vm.opponentSkin.boardColor)
                        // Alt Yarı: Oyuncu Skin
                        Rectangle()
                            .fill(vm.playerSkin.boardColor)
                    }
                    .frame(maxWidth: 300, maxHeight: 450)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 2))
                    
                    // Orta Çizgi
                    Rectangle().fill(Color.white.opacity(0.2)).frame(width: 280, height: 2)
                    
                    VStack {
                        // RAKİP ELİ
                        HStack(spacing: -15) {
                            ForEach(vm.opponentHand) { card in
                                CardView(card: card, isFaceUp: false).frame(width: 60, height: 90).rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                            }
                        }.padding(.top, 20)
                        Spacer()
                        
                        // DROP ZONE
                        ZStack {
                            // Hedef Alanı Çizgisi
                            RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                                .fill(vm.tableCard != nil ? Color.clear : (vm.turn == .player ? vm.playerSkin.accentColor : Color.gray.opacity(0.3)))
                                .frame(width: 100, height: 140)
                                .scaleEffect(vm.turn == .player && vm.tableCard == nil ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: vm.turn)
                            
                            if let card = vm.tableCard {
                                CardView(card: card, isFaceUp: true, isTableCard: true)
                                    .frame(width: 100, height: 140)
                                    .offset(x: vm.resolutionCard != nil ? -30 : 0)
                                    .rotationEffect(.degrees(vm.resolutionCard != nil ? -5 : 0))
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            if let resCard = vm.resolutionCard {
                                CardView(card: resCard, isFaceUp: true, isTableCard: true, status: vm.tableCardStatus)
                                    .frame(width: 100, height: 140)
                                    .offset(x: 30, y: 10)
                                    .rotationEffect(.degrees(5))
                                    .transition(.scale.combined(with: .opacity))
                                    .zIndex(10)
                            } else if vm.turn == .player && vm.tableCard == nil {
                                VStack { Image(systemName: "arrow.down.circle"); Text("KARTI AT").font(.caption2).bold() }.foregroundColor(vm.playerSkin.accentColor)
                            }
                        }
                        Spacer()
                    }
                }
                .rotation3DEffect(.degrees(25), axis: (x: 1, y: 0, z: 0))
                .offset(y: vm.shakeTable ? -10 : 0)
                .animation(.default, value: vm.shakeTable)
                .animation(.spring(), value: vm.resolutionCard)
                
                Spacer()
                
                // OYUNCU ELİ
                ZStack(alignment: .bottom) {
                    HStack(spacing: -10) {
                        ForEach(vm.playerHand) { card in
                            GeometryReader { geo in
                                let isDragging = draggingCard?.id == card.id
                                CardView(card: card, isFaceUp: true, isPlayerTurn: vm.turn == .player)
                                    .scaleEffect(isDragging ? 1.2 : 1.0)
                                    .offset(isDragging ? dragOffset : .zero)
                                    .zIndex(isDragging ? 100 : 0)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if vm.turn == .player && vm.tableCardStatus == .normal {
                                                    if draggingCard == nil { draggingCard = card }
                                                    dragOffset = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if let dragging = draggingCard {
                                                    let dropLocation = geo.frame(in: .global).midY + value.translation.height
                                                    let screenHeight = UIScreen.main.bounds.height
                                                    if dropLocation > screenHeight * 0.3 && dropLocation < screenHeight * 0.6 {
                                                        vm.playerPlayedCard(card: dragging)
                                                    }
                                                }
                                                draggingCard = nil
                                                dragOffset = .zero
                                            }
                                    )
                            }
                            .frame(width: 80, height: 120)
                            .rotationEffect(.degrees(Double(vm.playerHand.firstIndex(of: card)! - vm.playerHand.count/2) * 5))
                            .offset(y: draggingCard?.id == card.id ? -50 : 0)
                        }
                    }.frame(height: 150).padding(.bottom, 20)
                }.zIndex(50)
            }
        }
    }
}

// --- KART GÖRÜNÜMÜ ---
struct CardView: View {
    let card: GameCard
    let isFaceUp: Bool
    var isTableCard: Bool = false
    var isPlayerTurn: Bool = false
    var status: GameViewModel.CardStatus = .normal
    
    var skin: GameSkin {
        return card.ownerSkin ?? neonCyberSkin
    }
    
    private var frontBackground: AnyShapeStyle {
        if status == .wrong { return AnyShapeStyle(Color(hex: "fecaca")) }
        else if status == .correct { return AnyShapeStyle(Color(hex: "bbf7d0")) }
        else { return AnyShapeStyle(LinearGradient(colors: [.white, Color(hex: "fefce8")], startPoint: .topLeading, endPoint: .bottomTrailing)) }
    }
    private var borderColor: Color {
        if status == .wrong { return .red }
        if status == .correct { return .green }
        if isTableCard { return skin.accentColor }
        return (isPlayerTurn && card.ownerSkin?.id == "cyber") ? .blue : .gray.opacity(0.5)
    }
    private var borderWidth: CGFloat { (status != .normal || isPlayerTurn || isTableCard) ? 4 : 1 }
    private var cardShadowColor: Color {
        if status == .wrong { return .red.opacity(0.6) }
        if status == .correct { return .green.opacity(0.6) }
        return isPlayerTurn ? skin.accentColor.opacity(0.5) : .black.opacity(0.2)
    }
    private var badgeText: String {
        if status == .wrong { return "YANLIŞ" }
        if status == .correct { return "DOĞRU" }
        return card.type == .question ? "SORU" : "CEVAP"
    }
    private var badgeColor: Color {
        if status == .wrong { return .red }
        if status == .correct { return .green }
        return .yellow
    }
    
    var body: some View {
        ZStack {
            if isFaceUp {
                RoundedRectangle(cornerRadius: 12)
                    .fill(frontBackground)
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: borderWidth)
                            VStack {
                                HStack {
                                    Image(systemName: skin.iconName).font(.system(size: 10)).foregroundColor(skin.accentColor.opacity(0.5))
                                    Spacer()
                                    Image(systemName: skin.iconName).font(.system(size: 10)).foregroundColor(skin.accentColor.opacity(0.5))
                                }.padding(6)
                                Spacer()
                            }
                        }
                    )
                    .shadow(color: cardShadowColor, radius: 15)
                
                VStack {
                    if isTableCard {
                        Text(badgeText).font(.system(size: 8, weight: .bold)).padding(2).background(badgeColor).foregroundColor(.black).cornerRadius(2)
                    }
                    Spacer()
                    Text(card.text).font(.system(size: 14, weight: .heavy)).foregroundColor(.black).multilineTextAlignment(.center).padding(2)
                    Spacer()
                    Capsule().fill(Color.black.opacity(0.1)).frame(width: 20, height: 4).padding(.bottom, 5)
                }
            } else {
                RoundedRectangle(cornerRadius: 12).fill(skin.cardBackPattern)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 2).padding(4))
                Image(systemName: skin.iconName).font(.system(size: 30)).foregroundColor(.white.opacity(0.8)).shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            }
        }
    }
}

// --- MENÜ GÖRÜNÜMÜ (GÜNCELLENDİ) ---
struct MenuView: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        VStack(spacing: 30) {
            VStack {
                Text("Memora").font(.system(size: 70, weight: .black)).foregroundColor(.yellow)
                Text("DUEL").font(.system(size: 55, weight: .black)).foregroundColor(.white).offset(y: -20)
            }.shadow(color: .yellow.opacity(0.5), radius: 20).padding(.bottom, 20)
            
            if vm.menuState == "mode_select" {
                VStack(spacing: 15) {
                    Button(action: { withAnimation { vm.menuState = "category_select" } }) {
                        HStack { Image(systemName: "brain.head.profile"); Text("YAPAY ZEKA İLE OYNA") }
                        .font(.title3).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding(20)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)).cornerRadius(20).shadow(color: .blue.opacity(0.5), radius: 10)
                    }
                    // Online oyunuc butonu
                    Button(action: {}) {
                        HStack { Image(systemName: "person.2.fill"); VStack(alignment: .leading) { Text("GERÇEK OYUNCULAR"); Text("YAKINDA").font(.caption).opacity(0.7) } }
                        .font(.title3).bold().foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity).padding(20).background(Color.gray.opacity(0.3)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 2))
                    }.disabled(true)
                    
                    
                    // Skin seçimi butonu
                    Button(action: { withAnimation { vm.menuState = "skin_select" } }) {
                        HStack { Image(systemName: "paintbrush.fill"); Text("GÖRÜNÜM & TASARIM") }
                        .font(.title3).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding(20)
                        .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)).cornerRadius(20).shadow(color: .pink.opacity(0.5), radius: 10)
                    }
                }.padding(.horizontal, 40).transition(.move(edge: .leading))
                
            } else if vm.menuState == "category_select" {
                // ... (Kategori Seçimi aynı kalıyor)
                VStack(spacing: 15) {
                    Text("VERİ SETİ SEÇ").font(.headline).foregroundColor(.gray)
                    ScrollView {
                        VStack(spacing: 12) {
                            CategoryButton(title: "🇬🇧 İngilizce Kelimeler", color1: .orange, color2: .red) { vm.startGame(dataSet: englishDataSet) }
                            CategoryButton(title: "🧮 Matematik", color1: .purple, color2: .indigo) { vm.startGame(dataSet: mathDataSet) }
                            CategoryButton(title: "🌍 Başkentler (Coğrafya)", color1: .green, color2: .teal) { vm.startGame(dataSet: geographyDataSet) }
                            CategoryButton(title: "🔬 Fen Bilimleri", color1: .pink, color2: .purple) { vm.startGame(dataSet: cultureDataSet) }
                        }
                        .padding(.horizontal, 40)
                    }.frame(maxHeight: 300)
                    Button(action: { withAnimation { vm.goBackToModeSelect() } }) {
                        HStack { Image(systemName: "arrow.left"); Text("Geri Dön") }.foregroundColor(.white.opacity(0.7)).padding()
                    }
                }.transition(.move(edge: .trailing))
                
            } else if vm.menuState == "skin_select" {
                // Skin seçim ekranı
                VStack(spacing: 20) {
                    Text("SKIN SEÇİMİ").font(.headline).foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(GameSkin.allSkins) { skin in
                                Button(action: {
                                    withAnimation { vm.playerSkin = skin }
                                }) {
                                    VStack {
                                        // Önizleme Kartı
                                        ZStack {
                                            // Tahta Rengi Önizleme
                                            Circle()
                                                .fill(skin.boardColor)
                                                .frame(width: 120, height: 120)
                                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                                            
                                            // Kart Arkası Önizleme (Hafif dönmüş)
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(skin.cardBackPattern)
                                                .frame(width: 60, height: 90)
                                                .overlay(
                                                    Image(systemName: skin.iconName)
                                                        .font(.title)
                                                        .foregroundColor(.white)
                                                )
                                                .rotationEffect(.degrees(10))
                                                .shadow(radius: 5)
                                        }
                                        
                                        Text(skin.name)
                                            .font(.caption).bold()
                                            .foregroundColor(vm.playerSkin.id == skin.id ? .white : .gray)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(vm.playerSkin.id == skin.id ? Color.blue.opacity(0.3) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(vm.playerSkin.id == skin.id ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: { withAnimation { vm.goBackToModeSelect() } }) {
                        HStack { Image(systemName: "checkmark.circle.fill"); Text("SEÇ VE DÖN") }
                            .font(.headline).bold().foregroundColor(.white).padding().frame(maxWidth: .infinity)
                            .background(Color.green).cornerRadius(15).shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                }
                .transition(.move(edge: .trailing))
            }
        }
    }
}

struct CategoryButton: View {
    let title: String; let color1: Color; let color2: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding().background(LinearGradient(colors: [color1, color2], startPoint: .leading, endPoint: .trailing)).cornerRadius(15).shadow(color: color1.opacity(0.3), radius: 5)
        }
    }
}

struct ResultView: View {
    @ObservedObject var vm: GameViewModel
    var isWin: Bool { vm.playerHealth > vm.opponentHealth }
    var isDraw: Bool { vm.playerHealth == vm.opponentHealth }
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isWin ? "trophy.fill" : (isDraw ? "scale.3d" : "xmark.shield.fill"))
                .font(.system(size: 100)).foregroundColor(isWin ? .yellow : (isDraw ? .blue : .red)).padding().shadow(color: isWin ? .yellow : (isDraw ? .blue : .red), radius: 20)
            Text(isWin ? "KAZANDIN!" : (isDraw ? "BERABERE" : "YENİLGİ")).font(.largeTitle.bold()).foregroundColor(.white)
            Text("Sen: \(vm.playerHealth) HP - Rakip: \(vm.opponentHealth) HP").font(.title2).bold().foregroundColor(.gray)
            Text(isWin ? "Mükemmel strateji!" : (isDraw ? "Çok çekişmeliydi!" : "Bir dahaki sefere...")).foregroundColor(.white.opacity(0.7))
            Button(action: { vm.goBackToMenu() }) {
                HStack { Image(systemName: "arrow.counterclockwise"); Text("MENÜYE DÖN") }
                .bold().padding().background(Color.white).foregroundColor(.black).cornerRadius(30)
            }.padding(.top, 20)
        }
    }
}

struct ParticleView: View {
    let particle: Particle; @State private var time: Double = 0.0
    var body: some View {
        Circle().fill(particle.color).frame(width: 20, height: 20).opacity(1.0 - time).scaleEffect(1.0 - time)
            .offset(x: particle.x + (Double.random(in: -100...100) * time), y: particle.y + (Double.random(in: -100...100) * time))
            .onAppear { withAnimation(.easeOut(duration: 1.0)) { time = 1.0 } }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}
extension Font { func black() -> Font { return .system(size: 32, weight: .black, design: .rounded) } }
struct ContentView_Previews: PreviewProvider { static var previews: some View { ContentView() } }
