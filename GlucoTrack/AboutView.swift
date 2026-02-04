//
//  AboutView.swift
//  GlucoTrack
//
//  Created by Gökhan Akkız on 3.02.2026.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Başlık
                Text("GlucoTrack")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [PremiumPalette.accent, PremiumPalette.calmTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Uygulama açıklaması ve kullanıcı bilgisi kartı
                VStack(alignment: .leading, spacing: 16) {
                    Text("Uygulama Hakkında")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("""
GlucoTrack, diyabet takibi için glukoz ve insülin kayıtları yapmanızı sağlar.

GlucoTrack, diyabet takibi için özel olarak geliştirilmiş bir mobil uygulamadır. 
Bu uygulama sayesinde kan şekeri değerlerinizi, insülin bazal ve bolus kayıtlarınızı kolayca takip edebilir, analiz edebilir ve düzenli olarak kontrol edebilirsiniz.
""")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Diyabet Hakkında")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Text("""
Diyabet, vücudun kan şekeri seviyelerini düzenleme yeteneğinde sorun yaşamasıyla karakterize bir durumdur. 
Düzenli takip ve kayıtlar Glukoz ve İnsülin seviyenizi kontrol altında tutmanıza yardımcı olur.
""")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Geliştirici Bilgileri")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Adı Soyadı: Gökhan Akkız")
                        Text("E-posta: gokhanakkiz@hotmail.com")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .premiumCard(padding: 20, radius: 18)
            }
            .padding()
        }
        .navigationTitle("Hakkında")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
