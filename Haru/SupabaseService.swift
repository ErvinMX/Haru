
//
//  SupabaseService.swift
//  Haru
//
//  Created by Ervin Sng on 20/9/26.
//

import Foundation
import Supabase


final class SupabaseService {

    static let shared = SupabaseService()


    private let supabaseURL = URL(
        string: "https://dfkydlznavniytpzjsrq.supabase.co"
    )!


    private let supabaseKey =
        "sb_publishable_H8muOjNyEf_dhuNrXw0IVg_MsEqTGTR"


    let client: SupabaseClient


    private init() {

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }


    // MARK: - New Haru vocabulary (all three difficulties)
    func fetchWords() async throws -> [TopikWord] {
        var allWords: [TopikWord] = []
        let pageSize = 1000
        var offset = 0

        while true {
            let batch: [TopikWord] = try await client
                .from("haru_vocabulary")
                .select("id,hangul,english,level,theme,part_of_speech,example_ko,example_en")
                .order("id", ascending: true)
                .range(from: offset, to: offset + pageSize - 1)
                .execute().value

            allWords.append(contentsOf: batch)

            if batch.count < pageSize {
                break
            }

            offset += pageSize
        }

        return allWords
    }


    // Compatibility for existing callers while migrating screens.
    func fetchTopikWords() async throws -> [TopikWord] {
        try await fetchWords()
    }
}
