%define _ballerina_name ballerina
%define _ballerina_version
%define _ballerina_tools_dir

Name:           ballerina-runtime
Version:
Release:        1
Summary:        Ballerina is a general purpose, concurrent and strongly typed programming language with both textual and graphical syntaxes, optimized for integration.
License:        Apache license 2.0
URL:            https://ballerinalang.org/

# Disable Automatic Dependencies
AutoReqProv: no
%define _rpmfilename %%{ARCH}/ballerina-runtime-linux-installer-x64-%{_ballerina_version}.rpm
# Disable Jar repacking
%define __jar_repack %{nil}

%description
Ballerina allows you to code with a statically-typed, interaction-centric programming language where microservices, APIs, and streams are first-class constructs. You can use your preferred IDE and CI/CD tools. Discover, consume, and share packages that integrate endpoints with Ballerina Central. Build binaries, containers, and Kubernetes artifacts and deploy as chaos-ready services on cloud and serverless infrastructure. Integrate distributed endpoints with simple syntax for resiliency, circuit breakers, transactions, and events.

%pre
rm -f /usr/bin/ballerina > /dev/null 2>&1

%prep
rm -rf %{_topdir}/BUILD/*
cp -r %{_topdir}/SOURCES/%{_ballerina_tools_dir}/* %{_topdir}/BUILD/
%build
%install
rm -rf $RPM_BUILD_ROOT
install -d %{buildroot}/usr/lib/ballerina/%{_ballerina_name}-runtime-%{_ballerina_version}
cp -r cp -r bin bre logs resources samples src %{buildroot}/usr/lib/ballerina/%{_ballerina_name}-runtime-%{_ballerina_version}/

%post
ln -sf /usr/lib/ballerina/%{_ballerina_name}-runtime-%{_ballerina_version}/bin/ballerina /usr/bin/%{_ballerina_name}
echo 'export BALLERINA_HOME=' >> /etc/profile.d/wso2.sh
chmod 0755 /etc/profile.d/wso2.sh
echo "Ballerina Runtime %{_ballerina_version} is successfully installed in /usr/lib/ballerina/%{_ballerina_name}-runtime-%{_ballerina_version}"

%postun
sed -i.bak '\:SED_BALLERINA_HOME:d' /etc/profile.d/wso2.sh
if [ "$(readlink /usr/bin/ballerina)" = "/usr/lib/ballerina/ballerina-runtime-%{_ballerina_version}/bin/ballerina" ]
then
  rm -f /usr/bin/ballerina
fi
echo "Ballerina Runtime %{_ballerina_version} is successfully uninstalled"

%clean
rm -rf %{_topdir}/BUILD/*
rm -rf %{buildroot}

%files
/usr/lib/ballerina/%{_ballerina_name}-runtime-%{_ballerina_version}
%doc COPYRIGHT LICENSE README