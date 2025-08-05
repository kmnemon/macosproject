//
//  main.swift
//  TextParser
//
//  Created by Paul Hudson on 30/03/2022.
//

import ArgumentParser
import Foundation
import NaturalLanguage

@main
struct App: ParsableCommand {
    @Argument(help: "The text you want to analyze")
    var input: [String]
    
    @Flag(help: "everything")
    var everything = false
    
    @Flag(name: .shortAndLong, help: "Show detected language.")
    var detectLanguage = false
    
    @Flag(name: .shortAndLong, help: "Prints how positive or negative the input is.")
    var sentimentAnalysis = false
    
    @Flag(name: .shortAndLong, help: "Shows the stem form of each word in the input.")
    var lemmatize = false
    
    @Flag(name: .shortAndLong, help: "Prints alternative words for each word in the input.")
    var alternatives = false
    
    @Option(name: .shortAndLong)
    var distance: NLDistance = 0.0
    
    @Flag(name: .shortAndLong, help: "Prints names of people, places, and organizations in the input.")
    var names = false
    
    @Flag(name: .shortAndLong, help: "")
    var orgs = false
    
    @Flag(name: .shortAndLong, help: "")
    var persons = false
    
    @Flag(name: .shortAndLong, help: "")
    var places = false
    
    @Option(name: .shortAndLong, help: "The maximum number of alternatives to suggest")
    var maximumAlternatives = 10
    
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "analyze", abstract: "Analyzes input text using a range of natural language approaches.")
    }
    
    mutating func run() {
        if everything {
            detectLanguage = true
            sentimentAnalysis = true
            lemmatize = true
            alternatives = true
            names = true
        }
        
        let text = input.joined(separator: " ")
        
        var language:  NLLanguage = .english
        if detectLanguage {
            language = NLLanguageRecognizer.dominantLanguage(for: text) ?? .undetermined
            print()
            print("Detected language: \(language.rawValue)")
        }
        
        print()
        let sentiment = sentiment(for: text)
        print("Sentiment analysis: \(sentiment)")
        
        lazy var lemma = lemmatize(string: text)
        
        if lemmatize {
            print()
            print("Found the following lemma:")
            print("\t", lemma.formatted(.list(type: .and)))
        }
        
        if alternatives {
            print()
            print("Found the following alternatives:")
            
            for word in lemma {
                let embeddings = embeddings(for: word, language)
                print("\t\(word): ", embeddings.formatted(.list(type: .and)))
            }
        }
        
        if names {
            let entities = entities(for: text)
            print()
            print("Found the following entities:")
            
            for entity in entities {
                print("\t", entity)
            }
        }
    }
    
    func sentiment(for string: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = string
        
        let (sentiment, _) = tagger.tag(at: string.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(sentiment?.rawValue ?? "0") ?? 0
    }
    
    func embeddings(for word: String, _ lang: NLLanguage) -> [String] {
        var results = [String]()
        
        if let embedding = NLEmbedding.wordEmbedding(for: lang) {
            let similarWords = embedding.neighbors(for: word, maximumCount: maximumAlternatives)
            
            for word in similarWords {
                if word.1 <= distance {
                    results.append("\(word.0) has a distance of \(word.1)")
                }
            }
        }
        
        return results
    }
    
    func lemmatize(string: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = string
        
        var results = [String]()
        
        tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .lemma) { tag, range in
            let stemForm = tag?.rawValue ?? String(string[range]).trimmingCharacters(in: .whitespaces)
            
            if stemForm.isEmpty == false {
                results.append(stemForm)
            }
            
            return true
        }
        
        return results
    }
    
    func entities(for string: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = string
        var results = [String]()
        
        tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .nameType, options: .joinNames) { tag, range in
            guard let tag = tag else { return true }
            
            let match = String(string[range])
            
            switch tag {
            case .organizationName:
                if orgs {
                    results.append("Organization: \(match)")
                }
            case .personalName:
                if persons {
                    results.append("Person: \(match)")
                }
            case .placeName:
                if places {
                    results.append("Place: \(match)")
                }
            default:
                break
            }
            
            return true
        }
        
        return results
    }
}
