//
//  APIClient+Pages.swift
//  Cafe
//
//  Pages and layout presets API endpoints
//

import Foundation

extension APIClient {
    // MARK: - Pages

    func getPages() async throws -> [Page] {
        let request = try authorizedRequest(path: "/pages/", method: "GET")
        return try await performRequest(request)
    }

    func getPage(id: Int) async throws -> Page {
        let request = try authorizedRequest(path: "/pages/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createPage(_ page: PageCreate) async throws -> Page {
        var request = try authorizedRequest(path: "/pages/", method: "POST")
        request.httpBody = try JSONEncoder().encode(page)
        return try await performRequest(request)
    }

    func updatePage(id: Int, _ page: PageUpdate) async throws -> Page {
        var request = try authorizedRequest(path: "/pages/\(id)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(page)
        return try await performRequest(request)
    }

    func deletePage(id: Int) async throws {
        let request = try authorizedRequest(path: "/pages/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Page Sharing

    func sharePage(id: Int, share: PageShareCreate) async throws -> [PageShare] {
        var request = try authorizedRequest(path: "/pages/\(id)/share", method: "POST")
        request.httpBody = try JSONEncoder().encode(share)
        return try await performRequest(request)
    }

    func unsharePage(pageId: Int, username: String) async throws {
        let request = try authorizedRequest(path: "/pages/\(pageId)/share/\(username)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Layout Presets

    func getLayoutPresets() async throws -> [LayoutPreset] {
        let request = try authorizedRequest(path: "/layout-presets/", method: "GET")
        return try await performRequest(request)
    }

    func getLayoutPreset(id: Int) async throws -> LayoutPreset {
        let request = try authorizedRequest(path: "/layout-presets/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createLayoutPreset(_ preset: LayoutPresetCreate) async throws -> LayoutPreset {
        var request = try authorizedRequest(path: "/layout-presets/", method: "POST")
        request.httpBody = try JSONEncoder().encode(preset)
        return try await performRequest(request)
    }

    func createLayoutPresetFromPage(pageId: Int, name: String, description: String?, isPublic: Bool) async throws -> LayoutPreset {
        struct PresetFromPageRequest: Codable {
            let name: String
            let description: String?
            let isPublic: Bool
        }

        var request = try authorizedRequest(path: "/layout-presets/from-page/\(pageId)", method: "POST")
        let body = PresetFromPageRequest(name: name, description: description, isPublic: isPublic)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    func updateLayoutPreset(id: Int, _ preset: LayoutPresetUpdate) async throws -> LayoutPreset {
        var request = try authorizedRequest(path: "/layout-presets/\(id)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(preset)
        return try await performRequest(request)
    }

    func deleteLayoutPreset(id: Int) async throws {
        let request = try authorizedRequest(path: "/layout-presets/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    func applyLayoutPreset(pageId: Int, presetId: Int) async throws -> Page {
        let request = try authorizedRequest(path: "/pages/\(pageId)/apply-preset/\(presetId)", method: "POST")
        return try await performRequest(request)
    }
}
