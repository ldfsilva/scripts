#!/usr/bin/env python
"""
Script for gathering VM, datastore and ESXi server information.


It will look for all VMs with the given vcenter server and
iterate through them collecting its detail. The collected data
will be saved onto a json file for further parsing and comparison
if required.
"""

import json
import csv
import argparse
import atexit

from getpass import getpass
from collections import namedtuple
from datetime import datetime

from pyVim import connect
from pyVmomi import vmodl
from pyVmomi import vim


# script execution time
d = datetime.now()
date = d.strftime("%Y%m%d_%H%M%S")


def get_args():
    """Builds argument parser
    """

    parser = argparse.ArgumentParser(
        description='Gather VM, Datastore and ESXi host information')

    parser.add_argument('-s', '--host',
                        required=True,
                        action='store',
                        help='vSphere service to connect to')

    parser.add_argument('-o', '--port',
                        type=int,
                        default=443,
                        action='store',
                        help='Port to connect on')

    parser.add_argument('-u', '--user',
                        required=True,
                        action='store',
                        help='User name to use when connecting to host')

    parser.add_argument('-p', '--password',
                        required=False,
                        action='store',
                        help='Password to use when connecting to host')

    parser.add_argument('-S', '--disable_ssl_verification',
                        required=False,
                        action='store_true',
                        help='Disable ssl host certificate verification')

    args = parser.parse_args()
    if not args.password:
        args.password = getpass(
            prompt="Provide password for %s user: " % args.user
        )

    return args


def get_host_data(host):
    """Get ESXi host information
    """

    # host config info
    HostConfig = namedtuple('HostConfig', 'name port sslThumbprint')
    host_config = host.summary.config

    host_config = HostConfig(
        name = host_config.name,
        port = host_config.port,
        sslThumbprint = host_config.sslThumbprint,
    )

    # host hardware info
    HostHW = namedtuple('HostHW', 'uuid vendor model memorySize cpuModel \
        cpuMhz numCpuPkgs numCpuCores numCpuThreads numNics numHBAs ')
    host_hardware = host.summary.hardware

    host_hardware = HostHW(
        uuid = host_hardware.uuid,
        vendor = host_hardware.vendor,
        model = host_hardware.model,
        memorySize = host_hardware.memorySize,
        cpuModel = host_hardware.cpuModel,
        cpuMhz = host_hardware.cpuMhz,
        numCpuPkgs = host_hardware.numCpuPkgs,
        numCpuCores = host_hardware.numCpuCores,
        numCpuThreads = host_hardware.numCpuThreads,
        numNics = host_hardware.numNics,
        numHBAs = host_hardware.numHBAs,
    )

    # host product info
    HostProduct = namedtuple('HostProduct', 'name fullName vendor \
        version build apiVersion licenseProductName licenseProductVersion')
    host_product = host.config.product

    host_product = HostProduct(
        name = host_product.name,
        fullName = host_product.fullName,
        vendor = host_product.vendor,
        version = host_product.version,
        build = host_product.build,
        apiVersion = host_product.apiVersion,
        licenseProductName = host_product.licenseProductName,
        licenseProductVersion = host_product.licenseProductVersion,
    )

    # host runtime info
    HostRuntime = namedtuple('HostRuntime', 'powerState bootTime')
    host_runtime = host.runtime

    host_runtime = HostRuntime(
        powerState = host_runtime.powerState,
        bootTime = host_runtime.bootTime,
    )

    # host summary info
    HostSummary = namedtuple('HostSummary', 'managementServerIp \
        overallStatus rebootRequired maxEVCModeKey currentEVCModeKey')
    host_summary = host.summary

    host_summary = HostSummary(
        managementServerIp = host_summary.managementServerIp,
        overallStatus = host_summary.overallStatus,
        rebootRequired = host_summary.rebootRequired,
        maxEVCModeKey = host_summary.maxEVCModeKey,
        currentEVCModeKey = host_summary.currentEVCModeKey,
    )

    host = {
        'config': host_config,
        'hardware': host_hardware,
        'product': host_product,
        'runtime': host_runtime,
        'summary': host_summary,
    }

    return host


def get_datastore_data(datastore):
    """Get datastore information
    """

    # datastore info
    Datastore = namedtuple('Datastore', 'name capacity\
        freeSpace uncommitted url')
    ds_summary = datastore.summary

    ds_summary = Datastore(
        name = ds_summary.name,
        capacity = ds_summary.capacity,
        freeSpace = ds_summary.freeSpace,
        uncommitted = ds_summary.uncommitted,
        url = ds_summary.url,
    )

    return ds_summary


def get_vm_data(vm, fname):
    """Get VM information
    """
    vm_guest = vm.guest         # vm guest info
    vm_config = vm.config       # vm config info
    vm_runtime = vm.runtime     # vm runtime info
    vm_files = vm.config.files  # vm files info
    vm_summary = vm.summary.config      # vm summary info
    vm_hardware = vm.config.hardware    # vm hardware info

    # get relevant VM information from each section
    vm_data = {
        'runTime': date,
        'toolsStatus': vm_guest.toolsStatus,
        'toolsVersionStatus': vm_guest.toolsVersionStatus,
        'toolsVersionStatus2': vm_guest.toolsVersionStatus2,
        'toolsRunningStatus': vm_guest.toolsRunningStatus,
        'toolsVersion': vm_guest.toolsVersion,
        'guestId': vm_guest.guestId,
        'guestFamily': vm_guest.guestFamily,
        'guestFullName': vm_guest.guestFullName,
        'hostName': vm_guest.hostName,
        'ipAddress': vm_guest.ipAddress,
        'guestState': vm_guest.guestState,
        'uuid': vm_config.uuid,
        'instanceUuid': vm_config.instanceUuid,
        'name': vm_config.name,
        'version': vm_config.version,
        'annotation': vm_config.annotation,
        'vmPathName': vm_files.vmPathName,
        'snapshotDirectory': vm_files.snapshotDirectory,
        'suspendDirectory': vm_files.suspendDirectory,
        'logDirectory': vm_files.logDirectory,
        'numCPU': vm_hardware.numCPU,
        'numCoresPerSocket': vm_hardware.numCoresPerSocket,
        'memoryMB': vm_hardware.memoryMB,
        'powerState': vm_runtime.powerState,
        'connectionState': vm_runtime.connectionState,
        'bootTime': vm_runtime.bootTime,
        'host': vm_runtime.host.name,
        'template': vm_summary.template,
        'numEthernetCards': vm_summary.numEthernetCards,
        'numVirtualDisks': vm_summary.numVirtualDisks,
    }

    # get VM disk information
    disk_list = get_vm_disks(vm)
    # get VM ESXi host information
    host = get_host_data(vm.runtime.host)
    vm_data['disk_list'] = disk_list
    vm_data['esx_host'] = host

    # write VM information onto the given json file
    with open(fname, 'a') as fd:
        json.dump(vm_data, fd, cls=DateTimeEncoder)
        fd.write('\n')

#    return vm_data


class DateTimeEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()

        return json.JSONEncoder.default(self, o)


def get_vm_disks(vm):
    """Get VM disk information
    """
    disk_list = []
    vm_devices = vm.config.hardware.device

    for vm_device in vm_devices:
        if (vm_device.key >= 2000) and (vm_device.key < 3000):
            vm_disk = {
                'uuid': vm_device.backing.uuid,
                'label': vm_device.deviceInfo.label,
                'fileName': vm_device.backing.fileName,
                'unitNumber': vm_device.unitNumber,
                'capacityInKB': vm_device.capacityInKB,
            }

            # get datastore information
            datastore = get_datastore_data(vm_device.backing.datastore)

            disk_list.append([vm_disk, datastore])

    return disk_list


def main():
    args = get_args()

    # filename which collected data will be saved to
    fname = 'vms_detail_' + args.host + '_' + date + '.json'
    try:
        if args.disable_ssl_verification:
            service_instance = connect.SmartConnectNoSSL(host=args.host,
                                                         user=args.user,
                                                         pwd=args.password,
                                                         port=int(args.port))
        else:
            service_instance = connect.SmartConnect(host=args.host,
                                                    user=args.user,
                                                    pwd=args.password,
                                                    port=int(args.port))

        atexit.register(connect.Disconnect, service_instance)
        content = service_instance.RetrieveContent()

        container = content.rootFolder  # starting point to look into
        viewType = [vim.VirtualMachine] # object types to look for
        recursive = True    # whether we should look into it recursively
        containerView = content.viewManager.CreateContainerView(
            container, viewType, recursive)

        children = containerView.view

        for child in children:
            get_vm_data(child, fname)

    except vmodl.MethodFault as error:
        print("Caught vmodl fault : " + error.msg)
        return -1

    return 0


if __name__ == "__main__":
    main()

