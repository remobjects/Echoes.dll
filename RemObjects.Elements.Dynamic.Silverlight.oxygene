<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">
  <PropertyGroup>
    <ProductVersion>3.5</ProductVersion>
    <RootNamespace>RemObjects.Oxygene.Dynamic</RootNamespace>
    <StartupClass />
    <OutputType>library</OutputType>
    <AssemblyName>RemObjects.Elements.Dynamic</AssemblyName>
    <AllowGlobals>False</AllowGlobals>
    <AllowLegacyWith>False</AllowLegacyWith>
    <AllowLegacyOutParams>False</AllowLegacyOutParams>
    <AllowLegacyCreate>False</AllowLegacyCreate>
    <AllowUnsafeCode>False</AllowUnsafeCode>
    <ApplicationIcon />
    <Configuration Condition="'$(Configuration)' == ''">Release</Configuration>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <Name>RemObjects.Elements.Dynamic</Name>
    <ProjectTypeGuids>{89896941-7261-4476-8385-4DA3CE9FDB83};{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{656346D9-4656-40DA-A068-22D5425D4639}</ProjectTypeGuids>
    <Company />
    <ProjectGuid>{fd941037-2605-4957-875d-7496e78796ad}</ProjectGuid>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
    <Optimize>False</Optimize>
    <OutputPath>..\..\bin\Silverlight</OutputPath>
    <DefineConstants>DEBUG;TRACE;SILVERLIGHT;</DefineConstants>
    <GeneratePDB>True</GeneratePDB>
    <GenerateMDB>True</GenerateMDB>
    <EnableAsserts>True</EnableAsserts>
    <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
    <CaptureConsoleOutput>False</CaptureConsoleOutput>
    <StartMode>Project</StartMode>
    <RegisterForComInterop>False</RegisterForComInterop>
    <CpuType>anycpu</CpuType>
    <RuntimeVersion>v25</RuntimeVersion>
    <XmlDoc>False</XmlDoc>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <EnableUnmanagedDebugging>False</EnableUnmanagedDebugging>
    <SuppressWarnings />
    <CodeFlowAnalysis>True</CodeFlowAnalysis>
    <UseXmlDoc>False</UseXmlDoc>
    <XmlDocAllMembers>False</XmlDocAllMembers>
    <WarnOnCaseMismatch>False</WarnOnCaseMismatch>
    <RunCodeAnalysis>False</RunCodeAnalysis>
    <RequireExplicitLocalInitialization>False</RequireExplicitLocalInitialization>
    <FutureHelperClassName />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
    <Optimize>True</Optimize>
    <OutputPath>..\..\bin\Silverlight\</OutputPath>
    <DefineConstants>SILVERLIGHT;</DefineConstants>
    <GeneratePDB>False</GeneratePDB>
    <GenerateMDB>False</GenerateMDB>
    <EnableAsserts>False</EnableAsserts>
    <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
    <CaptureConsoleOutput>False</CaptureConsoleOutput>
    <StartMode>Project</StartMode>
    <RegisterForComInterop>False</RegisterForComInterop>
    <CpuType>anycpu</CpuType>
    <RuntimeVersion>v25</RuntimeVersion>
    <XmlDoc>False</XmlDoc>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <EnableUnmanagedDebugging>False</EnableUnmanagedDebugging>
    <DefineConstants>SILVERLIGHT</DefineConstants>
    <SuppressWarnings />
    <CodeFlowAnalysis>True</CodeFlowAnalysis>
    <UseXmlDoc>False</UseXmlDoc>
    <XmlDocAllMembers>False</XmlDocAllMembers>
    <WarnOnCaseMismatch>False</WarnOnCaseMismatch>
    <RunCodeAnalysis>False</RunCodeAnalysis>
    <RequireExplicitLocalInitialization>False</RequireExplicitLocalInitialization>
    <FutureHelperClassName />
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Binder.pas" />
    <Compile Include="OxygeneBinaryBinder.pas" />
    <Compile Include="OxygeneConversionBinder.pas" />
    <Compile Include="OxygeneInvokeMemberBinder.pas" />
    <Compile Include="OxygeneUnaryBinder.pas" />
    <Compile Include="Properties\AssemblyInfo.pas" />
    <EmbeddedResource Include="Properties\Resources.resx">
      <Generator>ResXFileCodeGenerator</Generator>
    </EmbeddedResource>
    <Compile Include="Properties\Resources.Designer.pas" />
    <None Include="Properties\Settings.settings">
      <Generator>SettingsSingleFileGenerator</Generator>
    </None>
    <Compile Include="Properties\Settings.Designer.pas" />
  </ItemGroup>
  <ItemGroup>
    <Folder Include="Properties\" />
  </ItemGroup>
  <ItemGroup>
    <Reference Include="mscorlib">
      <HintPath>c:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\Silverlight\v5.0\mscorlib.dll</HintPath>
    </Reference>
    <Reference Include="System">
      <HintPath>c:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\Silverlight\v5.0\system.dll</HintPath>
    </Reference>
    <Reference Include="System.Core">
      <HintPath>C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\Silverlight\v5.0\System.Core.dll</HintPath>
    </Reference>
    <Reference Include="System.Xml">
      <HintPath>c:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\Silverlight\v5.0\System.Xml.dll</HintPath>
    </Reference>
  </ItemGroup>
  <PropertyGroup>
    <!-- Indicate we are the Silverlight platform and set the registry base. This needs to be done
             prior to importing the common targets -->
    <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
    <FrameworkRegistryBase>Software\Microsoft\Microsoft SDKs\$(TargetFrameworkIdentifier)</FrameworkRegistryBase>
  </PropertyGroup>
  <ProjectExtensions />
  <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Oxygene\RemObjects.Oxygene.Echoes.targets" />
  <Import Project="$(MSBuildExtensionsPath)\Microsoft\Silverlight\v5.0\Microsoft.Silverlight.Common.targets" />
</Project>
