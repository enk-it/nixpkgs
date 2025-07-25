{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pytestCheckHook,
  python,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "psutil";
  version = "7.0.0";
  pyproject = true;

  inherit stdenv;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-e+nD66OL7Mtkleozr9mCpEB0t48oxDSh9RzAf9MVxFY=";
  };

  postPatch = ''
    # stick to the old SDK name for now
    # https://developer.apple.com/documentation/iokit/kiomasterportdefault/
    # https://developer.apple.com/documentation/iokit/kiomainportdefault/
    substituteInPlace psutil/arch/osx/cpu.c \
      --replace-fail kIOMainPortDefault kIOMasterPortDefault
  '';

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  # Segfaults on darwin:
  # https://github.com/giampaolo/psutil/issues/1715
  doCheck = !stdenv.hostPlatform.isDarwin;

  # In addition to the issues listed above there are some that occure due to
  # our sandboxing which we can work around by disabling some tests:
  # - cpu_times was flaky on darwin
  # - the other disabled tests are likely due to sandboxing (missing specific errors)
  enabledTestPaths = [
    # Note: $out must be referenced as test import paths are relative
    "${placeholder "out"}/${python.sitePackages}/psutil/tests/test_system.py"
  ];

  disabledTests = [
    # Some of the tests have build-system hardware-based impurities (like
    # reading temperature sensor values).  Disable them to avoid the failures
    # that sometimes result.
    "cpu_freq"
    "cpu_times"
    "disk_io_counters"
    "sensors_battery"
    "sensors_temperatures"
    "user"
    "test_disk_partitions" # problematic on Hydra's Linux builders, apparently
  ];

  pythonImportsCheck = [ "psutil" ];

  meta = with lib; {
    description = "Process and system utilization information interface";
    homepage = "https://github.com/giampaolo/psutil";
    changelog = "https://github.com/giampaolo/psutil/blob/release-${version}/HISTORY.rst";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}
