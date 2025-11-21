//
//  ContentView.swift
//  Memora Duel
//
//  Created by yunus emre yıldırım on 21.11.2025.
//

import SwiftUI
import Combine

// MARK: - 1. VERİ MODELLERİ

enum CardType {
    case question
    case answer
}

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
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
}

// Örnek Veriler
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

// MARK: - 2. OYUN MOTORU (VIEW MODEL)

class GameViewModel: ObservableObject {
    @Published var screen: String = "menu" // menu, game, result
    @Published var category: String = "english"
    
    @Published var playerHealth: Int = 5
    @Published var opponentHealth: Int = 5
    @Published var playerHand: [GameCard] = []
    @Published var opponentHand: [GameCard] = []
    @Published var tableCard: GameCard? = nil
    
    enum Turn { case player, opponent }
    @Published var turn: Turn = .opponent
    
    @Published var gameMessage: String = ""
    @Published var showTurnAlert: Bool = false
    @Published var shakeTable: Bool = false
    @Published var particles: [Particle] = []
    
    private var initialHealth = 5
    
    // Oyunu Başlat
    func startGame() {
        let rawData = category == "english" ? englishDataSet : mathDataSet
        
        var pHand: [GameCard] = []
        var oHand: [GameCard] = []
        
        // Dağıtım Mantığı: Her çift için karşılıklı dağıt
        for item in rawData {
            if Bool.random() {
                pHand.append(GameCard(dataId: item.id, text: item.q, type: .question))
                oHand.append(GameCard(dataId: item.id, text: item.a, type: .answer))
            } else {
                pHand.append(GameCard(dataId: item.id, text: item.a, type: .answer))
                oHand.append(GameCard(dataId: item.id, text: item.q, type: .question))
            }
        }
        
        playerHand = pHand.shuffled()
        opponentHand = oHand.shuffled()
        playerHealth = initialHealth
        opponentHealth = initialHealth
        tableCard = nil
        
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
                if self.opponentHand.isEmpty { self.endGame(); return }
                
                // Rastgele bir kart at
                let randomIndex = Int.random(in: 0..<self.opponentHand.count)
                let cardToPlay = self.opponentHand[randomIndex]
                
                withAnimation(.spring()) {
                    self.opponentHand.remove(at: randomIndex)
                    self.tableCard = cardToPlay
                    self.turn = .player
                    self.gameMessage = "SIRA SENDE! CEVABI BUL."
                }
                // Sıra oyuncuya geçti uyarısı
                self.showTurnAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.showTurnAlert = false }
                
            } else {
                // 2. AI SAVUNMA FAZI (Masa Doluysa)
                self.gameMessage = "RAKİP DÜŞÜNÜYOR..."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Cevabı bul
                    if let matchIndex = self.opponentHand.firstIndex(where: { $0.dataId == self.tableCard?.dataId }) {
                        // %90 ihtimalle bil (biraz hata payı olsun)
                        if Double.random(in: 0...1) > 0.1 {
                            // Doğru bildi
                            self.triggerParticles(color: .red)
                            withAnimation {
                                self.opponentHand.remove(at: matchIndex)
                                self.tableCard = nil // Masa temizlenir
                                self.turn = .opponent // Saldırı sırası yine rakipte
                                self.gameMessage = "RAKİP BİLDİ! YİNE SALDIRIYOR."
                            }
                            if self.opponentHand.isEmpty { self.endGame() }
                            else { self.runAILogic() } // Tekrar atağa geç
                        } else {
                            // Bilemedi (Hata yaptı)
                            self.aiFail()
                        }
                    } else {
                        // Elinde cevap yoksa
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
            self.turn = .player // Atak sırası oyuncuya geçer
            self.gameMessage = "RAKİP BİLEMEDİ! FIRSAT SENDE."
        }
        
        self.showTurnAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.showTurnAlert = false }
        
        if self.opponentHealth <= 0 { self.endGame() }
    }
    
    // Oyuncu Hamlesi
    func playerPlayedCard(card: GameCard) {
        // Kartı elden çıkar
        if let index = playerHand.firstIndex(where: { $0.id == card.id }) {
            withAnimation {
                playerHand.remove(at: index)
            }
        }
        
        // DURUM 1: ATAK (Masa Boş)
        if tableCard == nil {
            withAnimation(.spring()) {
                tableCard = card
                turn = .opponent
                gameMessage = "HAMLENİ YAPTIN. RAKİP BEKLİYOR..."
            }
            triggerParticles(color: .blue)
            if playerHand.isEmpty { endGame() }
            else { runAILogic() }
        }
        // DURUM 2: SAVUNMA (Masa Dolu)
        else if let currentTableCard = tableCard {
            if card.dataId == currentTableCard.dataId {
                // DOĞRU
                triggerParticles(color: .yellow)
                withAnimation {
                    tableCard = nil
                    turn = .player // Sıra bizde kalır (Atak hakkı)
                    gameMessage = "HARİKA! ŞİMDİ SALDIRI SIRASI SENDE."
                }
                
                self.showTurnAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.showTurnAlert = false }
                
                if playerHand.isEmpty { endGame() }
            } else {
                // YANLIŞ
                shakeTable = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.shakeTable = false }
                playerHealth -= 1
                gameMessage = "YANLIŞ KART! CAN KAYBETTİN."
                if playerHealth <= 0 { endGame() }
            }
        }
    }
    
    func triggerParticles(color: Color) {
        for _ in 0..<20 {
            let p = Particle(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                color: color
            )
            particles.append(p)
        }
        // Temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.particles.removeAll()
        }
    }
    
    func endGame() {
        screen = "result"
    }
}

// MARK: - 3. GÖRÜNÜMLER (VIEWS)

struct ContentView: View {
    @StateObject var vm = GameViewModel()
    
    var body: some View {
        ZStack {
            // Arkaplan
            RadialGradient(gradient: Gradient(colors: [Color(hex: "1e293b"), Color.black]), center: .center, startRadius: 2, endRadius: 650)
                .ignoresSafeArea()
            
            if vm.screen == "menu" {
                MenuView(vm: vm)
            } else if vm.screen == "game" {
                GameView(vm: vm)
            } else if vm.screen == "result" {
                ResultView(vm: vm)
            }
        }
        .statusBar(hidden: true)
    }
}

// --- OYUN EKRANI ---
struct GameView: View {
    @ObservedObject var vm: GameViewModel
    @State private var draggingCard: GameCard?
    @State private var dragOffset: CGSize = .zero
    @State private var dropZoneFrame: CGRect = .zero
    
    var body: some View {
        ZStack {
            // Parçacık Efektleri
            ForEach(vm.particles) { p in
                ParticleView(particle: p)
            }
            
            // SIRA UYARISI (POPUP)
            if vm.showTurnAlert {
                VStack {
                    Image(systemName: "sword.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("SIRA SENDE!")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                    Text("SALDIR VE KAZAN")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(40)
                .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(20)
                .shadow(color: .blue.opacity(0.6), radius: 20, x: 0, y: 0)
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
            
            VStack {
                // ÜST BAR (HUD)
                HStack {
                    VStack {
                        Text("RAKİP").font(.caption).bold().foregroundColor(.gray)
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < vm.opponentHealth ? Color.red : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 12)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("SEN").font(.caption).bold().foregroundColor(.gray)
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < vm.playerHealth ? .blue : .gray.opacity(0.3))
                                    .frame(width: 8, height: 12)
                            }
                        }
                    }
                }
                .frame(width: 350)
                .padding()
                
                Text(vm.gameMessage)
                    .font(.body).bold()
                    .padding(15)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .foregroundColor(vm.turn == .player ? .blue : .red)
                
                Spacer()
                
                // 3D MASA PERSPEKTİFİ
                ZStack {
                    // Masa Yüzeyi
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "0f172a").opacity(0.8))
                        .frame(maxWidth: 300, maxHeight: 450)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                    
                    VStack {
                        // RAKİP ELİ
                        HStack(spacing: -15) {
                            ForEach(vm.opponentHand) { card in
                                CardView(card: card, isFaceUp: false)
                                    .frame(width: 60, height: 90)
                                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0)) // Ters
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // DROP ZONE (HEDEF ALAN)
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                                .fill(
                                    vm.tableCard != nil ? Color.clear :
                                    (vm.turn == .player ? Color.blue : Color.gray.opacity(0.3))
                                )
                                .frame(width: 100, height: 140)
                                .background(GeometryReader { geo in
                                    Color.clear.onAppear {
                                        self.dropZoneFrame = geo.frame(in: .global)
                                    }
                                })
                                .scaleEffect(vm.turn == .player && vm.tableCard == nil ? 1.1 : 1.0)
                                .animation(.snappy(duration: 0.8).repeatForever(autoreverses: true), value: vm.turn)
                            
                            if let card = vm.tableCard {
                                CardView(card: card, isFaceUp: true, isTableCard: true)
                                    .frame(width: 100, height: 140)
                                    .transition(.scale.combined(with: .opacity))
                            } else if vm.turn == .player {
                                VStack {
                                    Image(systemName: "arrow.down.circle")
                                    Text("KARTI AT")
                                        .font(.caption2)
                                        .bold()
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .rotation3DEffect(.degrees(25), axis: (x: 1, y: 0, z: 0))
                .offset(y: vm.shakeTable ? -10 : 0) // Basit shake
                .animation(.default, value: vm.shakeTable)
                
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
                                    .zIndex(isDragging ? 100 : 0) // Sürüklerken en öne al
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if vm.turn == .player {
                                                    if draggingCard == nil { draggingCard = card }
                                                    dragOffset = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if let dragging = draggingCard {
                                                    // Drop Zone Kontrolü
                                                    // Basit koordinat kontrolü: Ekranın ortasına yaklaştı mı?
                                                    // Global frame kullanmak daha sağlıklı ama burada yaklaşık değer iş görür.
                                                    let dropLocation = geo.frame(in: .global).midY + value.translation.height
                                                    
                                                    // Ekran yüksekliğinin %30-60 aralığı masa sayılır
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
                            .offset(y: draggingCard?.id == card.id ? -50 : 0) // Seçileni hafif yukarı kaldır
                        }
                    }
                    .frame(height: 150)
                    .padding(.bottom, 20)
                }
                .zIndex(50) // Eli masanın üstünde tut
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
    
    var body: some View {
        ZStack {
            if isFaceUp {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [.white, Color(hex: "fefce8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTableCard ? Color.yellow :
                                (isPlayerTurn ? Color.blue : Color.gray),
                                lineWidth: isPlayerTurn || isTableCard ? 4 : 1
                            )
                    )
                    .shadow(color: isPlayerTurn ? .blue.opacity(0.5) : .black.opacity(0.2), radius: isPlayerTurn ? 10 : 5)
                
                VStack {
                    if isTableCard {
                        Text("HEDEF").font(.system(size: 8, weight: .bold)).padding(2).background(Color.yellow).foregroundColor(.black).cornerRadius(2)
                    }
                    Spacer()
                    Text(card.text)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(2)
                    Spacer()
                    Capsule().fill(Color.black.opacity(0.1)).frame(width: 20, height: 4).padding(.bottom, 5)
                }
            } else {
                // Kart Arkası
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "7f1d1d"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                            .padding(4)
                    )
                Image(systemName: "hexagon.fill")
                    .foregroundColor(.red.opacity(0.5))
            }
        }
    }
}

// --- MENÜ VE SONUÇ EKRANLARI ---

struct MenuView: View {
    @ObservedObject var vm: GameViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            VStack {
                Text("WORD").font(.system(size: 60, weight: .black)).foregroundColor(.yellow)
                Text("DUEL").font(.system(size: 60, weight: .bold)).foregroundColor(.white).offset(y: -20)
            }
            .shadow(color: .yellow.opacity(0.5), radius: 20)
            
            HStack(spacing: 20) {
                Button(action: { vm.category = "english" }) {
                    Text("English")
                        .bold()
                        .padding()
                        .frame(width: 100)
                        .background(vm.category == "english" ? Color.yellow : Color.gray.opacity(0.3))
                        .foregroundColor(vm.category == "english" ? .black : .white)
                        .cornerRadius(12)
                }
                
                Button(action: { vm.category = "math" }) {
                    Text("Math")
                        .bold()
                        .padding()
                        .frame(width: 100)
                        .background(vm.category == "math" ? Color.yellow : Color.gray.opacity(0.3))
                        .foregroundColor(vm.category == "math" ? .black : .white)
                        .cornerRadius(12)
                }
            }
            
            Button(action: { vm.startGame() }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("BAŞLA")
                }
                .font(.title2).bold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(20)
                .shadow(color: .blue.opacity(0.5), radius: 10)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct ResultView: View {
    @ObservedObject var vm: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: vm.playerHealth > 0 ? "trophy.fill" : "xmark.shield.fill")
                .font(.system(size: 100))
                .foregroundColor(vm.playerHealth > 0 ? .yellow : .red)
                .padding()
            
            Text(vm.playerHealth > 0 ? "KAZANDIN!" : "YENİLGİ")
                .foregroundColor(.white)
                .font(.largeTitle.bold())
                
            
            Text(vm.playerHealth > 0 ? "Harika iş çıkardın!" : "Bir dahaki sefere...")
                .foregroundColor(.gray)
            
            Button(action: { vm.screen = "menu" }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("MENÜYE DÖN")
                }
                .bold()
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(30)
            }
            .padding(.top, 20)
        }
    }
}

// --- EFEKTLER ---
struct ParticleView: View {
    let particle: Particle
    @State private var time: Double = 0.0
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: 8, height: 8)
            .opacity(1.0 - time)
            .scaleEffect(1.0 - time)
            .offset(
                x: particle.x + (Double.random(in: -100...100) * time),
                y: particle.y + (Double.random(in: -100...100) * time)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    time = 1.0
                }
            }
    }
}

// --- YARDIMCI EXTENSION ---
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Font {
    func black() -> Font {
        return .system(size: 32, weight: .black, design: .rounded)
    }
}

// Preview için
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
