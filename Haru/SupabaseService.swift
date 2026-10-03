//
//  SupabaseService.swift
//  Haru
//
//  Created by Ervin Sng on 20/9/26.
//

import Foundation
import Supabase

// MARK: - Supabase Client Configuration
final class SupabaseService {
    static let shared = SupabaseService()
    
    // Replace these with your actual Supabase URL and anon key from Step 1
    private let supabaseURL = URL(string: "YOUR_SUPABASE_PROJECT_URL")!
    private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}

// MARK: - TOPIK Word Model
struct TopikWord: Codable, Identifiable {
    let id: Int64
    let hangul: String
    let english: String
    let partOfSpeech: String?
    let topikLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case hangul
        case english
        case partOfSpeech = "part_of_speech"
        case topikLevel = "topik_level"
    }
}
