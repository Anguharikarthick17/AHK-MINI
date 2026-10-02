#!/usr/bin/env python3
import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    proj_dir = os.path.dirname(os.path.abspath(__file__))
    pbxproj_path = os.path.join(proj_dir, "AHKMini.xcodeproj", "project.pbxproj")
    
    # Collect all swift files in AHKMini
    ahk_mini_dir = os.path.join(proj_dir, "AHKMini")
    sources = []
    for root, _, files in os.walk(ahk_mini_dir):
        for f in sorted(files):
            if f.endswith(".swift"):
                rel_path = os.path.relpath(os.path.join(root, f), proj_dir)
                sources.append(rel_path)
    sources.sort()
    
    file_refs = {}
    build_files = {}
    
    for s in sources:
        fid = gen_id()
        bid = gen_id()
        name = os.path.basename(s)
        file_refs[s] = (fid, name)
        build_files[s] = (bid, fid, name)
        
    info_plist_id = gen_id()
    app_product_id = gen_id()
    main_group_id = gen_id()
    products_group_id = gen_id()
    
    native_target_id = gen_id()
    project_id = gen_id()
    sources_build_phase_id = gen_id()
    frameworks_build_phase_id = gen_id()
    resources_build_phase_id = gen_id()
    
    target_debug_cfg_id = gen_id()
    target_release_cfg_id = gen_id()
    target_cfg_list_id = gen_id()
    
    proj_debug_cfg_id = gen_id()
    proj_release_cfg_id = gen_id()
    proj_cfg_list_id = gen_id()
    
    # Generate PBXBuildFile section
    pbx_build_files = []
    for s, (bid, fid, name) in build_files.items():
        pbx_build_files.append(f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};")
        
    # Generate PBXFileReference section
    pbx_file_refs = []
    for s, (fid, name) in file_refs.items():
        pbx_file_refs.append(f"\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{os.path.basename(s)}\"; sourceTree = \"<group>\"; }};")
    pbx_file_refs.append(f"\t\t{info_plist_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    pbx_file_refs.append(f"\t\t{app_product_id} /* AHKMini.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AHKMini.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    
    # Group structure
    # AHKMini/App, Game, GameEngine, Games, Storage, UI, Window
    def build_group_structure():
        # Map directories to files
        dir_to_files = {}
        for s in sources:
            d = os.path.dirname(s)
            dir_to_files.setdefault(d, []).append(s)
            
        group_nodes = {}
        # Collect all directories under AHKMini
        all_dirs = set(dir_to_files.keys())
        for d in list(all_dirs):
            parts = d.split(os.sep)
            for i in range(1, len(parts)):
                all_dirs.add(os.sep.join(parts[:i]))
                
        dir_ids = {d: gen_id() for d in all_dirs}
        
        lines = []
        for d in sorted(all_dirs):
            gid = dir_ids[d]
            basename = os.path.basename(d)
            children = []
            
            # Subdirectories
            for sub in sorted(all_dirs):
                if os.path.dirname(sub) == d:
                    children.append(f"\t\t\t\t{dir_ids[sub]} /* {os.path.basename(sub)} */,")
                    
            # Files in this directory
            for f in dir_to_files.get(d, []):
                fid, fname = file_refs[f]
                children.append(f"\t\t\t\t{fid} /* {fname} */,")
                
            if d == "AHKMini/App":
                children.append(f"\t\t\t\t{info_plist_id} /* Info.plist */,")
                
            lines.append(f"""\t\t{gid} /* {basename} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(children)}
\t\t\t);
\t\t\tpath = "{basename}";
\t\t\tsourceTree = "<group>";
\t\t}};""")
            
        return dir_ids["AHKMini"], chr(10).join(lines)

    main_ahk_group_id, all_group_entries = build_group_structure()
    
    content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(pbx_build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(pbx_file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_build_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{main_ahk_group_id} /* AHKMini */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
{all_group_entries}
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_id} /* AHKMini.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{native_target_id} /* AHKMini */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {target_cfg_list_id} /* Build configuration list for PBXNativeTarget "AHKMini" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_build_phase_id} /* Sources */,
\t\t\t\t{frameworks_build_phase_id} /* Frameworks */,
\t\t\t\t{resources_build_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = AHKMini;
\t\t\tproductName = AHKMini;
\t\t\tproductReference = {app_product_id} /* AHKMini.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject "AHKMini" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{native_target_id} /* AHKMini */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_build_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_build_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join([f"\t\t\t\t{bid} /* {name} in Sources */," for bid, fid, name in build_files.values()])}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{proj_debug_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 12.0;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{proj_release_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 12.0;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{target_debug_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tINFOPLIST_FILE = AHKMini/App/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.ahk.mini";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{target_release_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tINFOPLIST_FILE = AHKMini/App/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.ahk.mini";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject "AHKMini" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_debug_cfg_id} /* Debug */,
\t\t\t\t{proj_release_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{target_cfg_list_id} /* Build configuration list for PBXNativeTarget "AHKMini" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{target_debug_cfg_id} /* Debug */,
\t\t\t\t{target_release_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {project_id} /* Project object */;
}}
"""
    with open(pbxproj_path, "w") as f:
        f.write(content)
    print(f"Generated {pbxproj_path} with {len(sources)} source files.")

if __name__ == "__main__":
    main()
