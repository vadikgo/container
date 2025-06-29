//===----------------------------------------------------------------------===//
// Copyright © 2025 Apple Inc. and the container project authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

//

import Foundation
import Testing

@testable import ContainerPlugin

struct PluginLoaderTest {
    @Test
    func testFindAll() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let factory = try setupMock(tempURL: tempURL)
        let loader = PluginLoader(
            pluginDirectories: [tempURL],
            pluginFactories: [factory], defaultResourcePath: tempURL)
        let plugins = loader.findPlugins()

        #expect(Set(plugins.map { $0.name }) == Set(["cli", "service"]))
    }

    @Test
    func testFindByName() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        let factory = try setupMock(tempURL: tempURL)
        let loader = PluginLoader(
            pluginDirectories: [tempURL],
            pluginFactories: [factory], defaultResourcePath: tempURL
        )

        #expect(loader.findPlugin(name: "cli")?.name == "cli")
        #expect(loader.findPlugin(name: "service")?.name == "service")
        #expect(loader.findPlugin(name: "throw") == nil)
    }

    private func setupMock(tempURL: URL) throws -> MockPluginFactory {
        let cliConfig = PluginConfig(abstract: "cli", author: "CLI", servicesConfig: nil)
        let cliPlugin: Plugin = Plugin(binaryURL: URL(filePath: "/bin/cli"), config: cliConfig)
        let serviceServicesConfig = PluginConfig.ServicesConfig(
            loadAtBoot: false,
            runAtLoad: false,
            services: [PluginConfig.Service(type: .runtime, description: nil)],
            defaultArguments: []
        )
        let serviceConfig = PluginConfig(abstract: "service", author: "SERVICE", servicesConfig: serviceServicesConfig)
        let servicePlugin: Plugin = Plugin(binaryURL: URL(filePath: "/bin/service"), config: serviceConfig)
        let mockPlugins = [
            "cli": cliPlugin,
            MockPluginFactory.throwSuffix: nil,
            "service": servicePlugin,
        ]

        return try MockPluginFactory(tempURL: tempURL, plugins: mockPlugins)
    }
}
