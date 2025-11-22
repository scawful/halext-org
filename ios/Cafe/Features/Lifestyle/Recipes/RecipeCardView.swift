//
//  RecipeCardView.swift
//  Cafe
//
//  Beautiful Pinterest-style recipe card view
//

import SwiftUI

struct RecipeCardView: View {
    @Environment(ThemeManager.self) var themeManager
    let recipe: Recipe
    let onTap: () -> Void

    @State private var isImageLoaded = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Recipe Image
                recipeImage
                    .frame(height: 180)
                    .clipped()

                // Recipe Info
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(themeManager.textColor)

                    // Match Score Badge (if available)
                    if let matchScore = recipe.matchScore {
                        matchScoreBadge(matchScore)
                    }

                    // Time and Difficulty
                    HStack(spacing: 12) {
                        Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)

                        Label(recipe.difficulty.displayName, systemImage: recipe.difficulty.icon)
                            .font(.caption)
                            .foregroundColor(difficultyColor(recipe.difficulty))
                    }

                    // Cuisine Tag
                    if let cuisine = recipe.cuisine {
                        Text(cuisine)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }

                    // Missing Ingredients Warning
                    if let missing = recipe.missingIngredients, !missing.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text("Missing \(missing.count) ingredient\(missing.count > 1 ? "s" : "")")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
                .padding(12)
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: themeManager.textColor.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var recipeImage: some View {
        if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholderImage
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                Text(recipe.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func matchScoreBadge(_ score: Double) -> some View {
        let percentage = Int(score * 100)
        let color: Color = score >= 0.8 ? .green : score >= 0.5 ? .orange : .red

        return HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
            Text("\(percentage)% match")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

// MARK: - Grid Card Variant

struct RecipeGridCardView: View {
    @Environment(ThemeManager.self) var themeManager
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Image
                recipeImage
                    .frame(height: 140)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(themeManager.textColor)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(recipe.totalTimeMinutes)m")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: themeManager.textColor.opacity(0.08), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var recipeImage: some View {
        if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        LinearGradient(
            colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundColor(.white)
        )
    }
}

// MARK: - Preview

#Preview("Recipe Card") {
    let sampleRecipe = Recipe(
        name: "Chicken Stir Fry",
        description: "A quick and delicious Asian-inspired chicken stir fry",
        ingredients: [
            RecipeIngredient(name: "chicken breast", amount: "1", unit: "lb"),
            RecipeIngredient(name: "broccoli", amount: "2", unit: "cups"),
            RecipeIngredient(name: "soy sauce", amount: "3", unit: "tbsp")
        ],
        instructions: [
            CookingStep(stepNumber: 1, instruction: "Cut chicken into bite-sized pieces"),
            CookingStep(stepNumber: 2, instruction: "Heat oil in wok over high heat")
        ],
        prepTimeMinutes: 15,
        cookTimeMinutes: 10,
        totalTimeMinutes: 25,
        servings: 4,
        difficulty: .beginner,
        cuisine: "Asian",
        tags: ["quick", "healthy", "weeknight"],
        matchedIngredients: ["chicken", "broccoli"],
        missingIngredients: ["soy sauce"],
        matchScore: 0.85
    )

    VStack(spacing: 16) {
        RecipeCardView(recipe: sampleRecipe, onTap: {})
            .frame(width: 300)

        RecipeGridCardView(recipe: sampleRecipe, onTap: {})
            .frame(width: 160)
    }
    .padding()
}
