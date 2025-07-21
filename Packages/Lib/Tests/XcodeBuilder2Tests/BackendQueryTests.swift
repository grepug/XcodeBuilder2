import Testing
import Foundation
@testable import Core
// Import specific types we need for testing
@testable import struct Core.BackendQuery
@testable import struct Core.ProjectValue
@testable import struct Core.SchemeValue
@testable import struct Core.BuildModelValue
@testable import struct Core.BuildLogValue
@testable import struct Core.CrashLogValue
@testable import struct Core.ProjectDetailData

@Suite("BackendQuery Tests")
struct BackendQueryTests {
    
    @Test("BackendQuery initialization")
    func testInitialization() {
        let query = BackendQuery<String>("test.key")
        #expect(query.key == "test.key")
        #expect(query.description == "BackendQuery(test.key)")
    }
    
    @Test("BackendQuery hashability")
    func testHashability() {
        let query1 = BackendQuery<String>("test.key")
        let query2 = BackendQuery<String>("test.key")
        let query3 = BackendQuery<String>("different.key")
        
        #expect(query1 == query2)
        #expect(query1 != query3)
        
        // Test hash consistency
        #expect(query1.hashValue == query2.hashValue)
        #expect(query1.hashValue != query3.hashValue)
        
        // Test that different types with same key have different hashes
        let intQuery = BackendQuery<Int>("test.key")
        #expect(query1.key == intQuery.key) // Same string key
        #expect(query1.hashValue != intQuery.hashValue) // But different hash due to type
    }
    
    @Test("Project query factory methods")
    func testProjectQueries() {
        let allIds = BackendQuery<[String]>.allProjectIds()
        #expect(allIds.key == "projects.all.ids")
        
        let project = BackendQuery<ProjectValue?>.project(id: "com.example.app")
        #expect(project.key == "project.com.example.app")
        
        let versionStrings = BackendQuery<[String: [String]]>.projectVersionStrings()
        #expect(versionStrings.key == "projects.versionStrings")
        
        let detail = BackendQuery<ProjectDetailData>.projectDetail(id: "com.example.app")
        #expect(detail.key == "project.com.example.app.detail")
        
        let buildVersions = BackendQuery<[String]>.buildVersionStrings(projectId: "com.example.app")
        #expect(buildVersions.key == "project.com.example.app.buildVersionStrings")
    }
    
    @Test("Scheme query factory methods")
    func testSchemeQueries() {
        let testUUID = UUID()
        
        let schemeIds = BackendQuery<[UUID]>.schemeIds(projectId: "com.example.app")
        #expect(schemeIds.key == "project.com.example.app.schemes.ids")
        
        let scheme = BackendQuery<SchemeValue?>.scheme(id: testUUID)
        #expect(scheme.key == "scheme.\(testUUID.uuidString)")
    }
    
    @Test("Build query factory methods")
    func testBuildQueries() {
        let testUUID1 = UUID()
        let testUUID2 = UUID()
        let schemeIds = [testUUID1, testUUID2]
        
        // Build IDs without version string
        let buildIds = BackendQuery<[UUID]>.buildIds(schemeIds: schemeIds, versionString: nil as String?)
        let expectedKey = "schemes.\(testUUID1.uuidString),\(testUUID2.uuidString).builds.ids"
        #expect(buildIds.key == expectedKey)
        
        // Build IDs with version string
        let buildIdsWithVersion = BackendQuery<[UUID]>.buildIds(schemeIds: schemeIds, versionString: "1.0.0")
        let expectedKeyWithVersion = "schemes.\(testUUID1.uuidString),\(testUUID2.uuidString).builds.ids.1.0.0"
        #expect(buildIdsWithVersion.key == expectedKeyWithVersion)
        
        let buildUUID = UUID()
        let build = BackendQuery<BuildModelValue?>.build(id: buildUUID)
        #expect(build.key == "build.\(buildUUID.uuidString)")
        
        let latestBuilds = BackendQuery<[BuildModelValue]>.latestBuilds(projectId: "com.example.app", limit: 5)
        #expect(latestBuilds.key == "project.com.example.app.latestBuilds.limit5")
    }
    
    @Test("Build log query factory methods")
    func testBuildLogQueries() {
        let buildUUID = UUID()
        let logUUID = UUID()
        
        // Basic log IDs
        let logIds = BackendQuery<[UUID]>.buildLogIds(buildId: buildUUID, includeDebug: false, category: nil as String?)
        #expect(logIds.key == "build.\(buildUUID.uuidString).logs.ids")
        
        // Log IDs with debug
        let debugLogIds = BackendQuery<[UUID]>.buildLogIds(buildId: buildUUID, includeDebug: true, category: nil as String?)
        #expect(debugLogIds.key == "build.\(buildUUID.uuidString).logs.ids.debug")
        
        // Log IDs with category
        let categoryLogIds = BackendQuery<[UUID]>.buildLogIds(buildId: buildUUID, includeDebug: false, category: "Build")
        #expect(categoryLogIds.key == "build.\(buildUUID.uuidString).logs.ids.categoryBuild")
        
        // Log IDs with both debug and category
        let fullLogIds = BackendQuery<[UUID]>.buildLogIds(buildId: buildUUID, includeDebug: true, category: "Error")
        #expect(fullLogIds.key == "build.\(buildUUID.uuidString).logs.ids.debug.categoryError")
        
        let buildLog = BackendQuery<BuildLogValue?>.buildLog(id: logUUID)
        #expect(buildLog.key == "buildLog.\(logUUID.uuidString)")
    }
    
    @Test("Crash log query factory methods")
    func testCrashLogQueries() {
        let buildUUID = UUID()
        
        let crashLogIds = BackendQuery<[String]>.crashLogIds(buildId: buildUUID)
        #expect(crashLogIds.key == "build.\(buildUUID.uuidString).crashLogs.ids")
        
        let crashLog = BackendQuery<CrashLogValue?>.crashLog(id: "crash-123")
        #expect(crashLog.key == "crashLog.crash-123")
    }
    
    @Test("Domain model convenience extensions")
    func testDomainModelQueries() {
        let testUUID = UUID()
        
        let domainProject = BackendQuery<Project?>.domainProject(id: "com.example.app")
        #expect(domainProject.key == "project.com.example.app")
        
        let domainScheme = BackendQuery<Scheme?>.domainScheme(id: testUUID)
        #expect(domainScheme.key == "scheme.\(testUUID.uuidString)")
        
        let domainBuild = BackendQuery<BuildModel?>.domainBuild(id: testUUID)
        #expect(domainBuild.key == "build.\(testUUID.uuidString)")
        
        let domainBuildLog = BackendQuery<BuildLog?>.domainBuildLog(id: testUUID)
        #expect(domainBuildLog.key == "buildLog.\(testUUID.uuidString)")
        
        let domainCrashLog = BackendQuery<CrashLog?>.domainCrashLog(id: "crash-456")
        #expect(domainCrashLog.key == "crashLog.crash-456")
        
        let domainLatestBuilds = BackendQuery<[BuildModel]>.domainLatestBuilds(projectId: "com.example.app", limit: 10)
        #expect(domainLatestBuilds.key == "project.com.example.app.latestBuilds.limit10")
    }
}

@Suite("Type-Safe Query Builder Tests")
struct QueryBuilderTests {
    
    @Test("ProjectQueries builders")
    func testProjectQueries() {
        #expect(ProjectQueries.allIds.key == "projects.all.ids")
        #expect(ProjectQueries.versionStrings.key == "projects.versionStrings")
        #expect(ProjectQueries.project(id: "test").key == "project.test")
        #expect(ProjectQueries.detail(id: "test").key == "project.test.detail")
        #expect(ProjectQueries.buildVersionStrings(id: "test").key == "project.test.buildVersionStrings")
        #expect(ProjectQueries.schemeIds(id: "test").key == "project.test.schemes.ids")
    }
    
    @Test("BuildQueries builders")
    func testBuildQueries() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        
        let buildIds = BuildQueries.buildIds(schemeIds: [uuid1, uuid2])
        let expectedKey = "schemes.\(uuid1.uuidString),\(uuid2.uuidString).builds.ids"
        #expect(buildIds.key == expectedKey)
        
        let build = BuildQueries.build(id: uuid1)
        #expect(build.key == "build.\(uuid1.uuidString)")
        
        let latestBuilds = BuildQueries.latestBuilds(projectId: "test", limit: 5)
        #expect(latestBuilds.key == "project.test.latestBuilds.limit5")
        
        let logIds = BuildQueries.logIds(buildId: uuid1, includeDebug: true, category: "Build")
        #expect(logIds.key == "build.\(uuid1.uuidString).logs.ids.debug.categoryBuild")
    }
    
    @Test("Domain query builders")
    func testDomainQueryBuilders() {
        let uuid = UUID()
        
        let domainProject = DomainProjectQueries.project(id: "test")
        #expect(domainProject.key == "project.test")
        
        let domainScheme = DomainSchemeQueries.scheme(id: uuid)
        #expect(domainScheme.key == "scheme.\(uuid.uuidString)")
        
        let domainBuild = DomainBuildQueries.build(id: uuid)
        #expect(domainBuild.key == "build.\(uuid.uuidString)")
        
        let domainBuildLog = DomainBuildLogQueries.buildLog(id: uuid)
        #expect(domainBuildLog.key == "buildLog.\(uuid.uuidString)")
        
        let domainCrashLog = DomainCrashLogQueries.crashLog(id: "test")
        #expect(domainCrashLog.key == "crashLog.test")
    }
}

@Suite("Query Utility Tests")
struct QueryUtilityTests {
    
    @Test("Query validation")
    func testQueryValidation() {
        let validQuery = BackendQuery<String>("project.com-example-app.schemes_ids")
        #expect(validQuery.isValid())
        
        let invalidQuery = BackendQuery<String>("project.com example.app") // contains space
        #expect(!invalidQuery.isValid())
        
        let emptyQuery = BackendQuery<String>("")
        #expect(!emptyQuery.isValid())
    }
    
    @Test("Query category and identifier")
    func testQueryComponents() {
        let query = BackendQuery<String>("project.com.example.app.detail")
        #expect(query.category == "project")
        #expect(query.identifier == "detail")
        
        let simpleQuery = BackendQuery<String>("projects")
        #expect(simpleQuery.category == "projects")
        #expect(simpleQuery.identifier == "projects")
    }
    
    @Test("Parameterized query builder")
    func testParameterizedQuery() {
        let parameters = ["limit": "10", "category": "Build", "debug": "true"]
        let query = BackendQuery<[String]>.parameterized(base: "logs", parameters: parameters)
        
        // Parameters should be sorted by key
        #expect(query.key == "logs.category:Build,debug:true,limit:10")
    }
    
    @Test("Dependent query builder")
    func testDependentQuery() {
        let query1 = BackendQuery<String>("project.test")
        let query2 = BackendQuery<[UUID]>("schemes.test")
        let dependent = BackendQuery<[String]>.dependent(on: query1, and: query2, key: "builds")
        
        #expect(dependent.key == "dependent.project.test.schemes.test.builds")
    }
}
