### AWS EKS


## step1: create  a IAM User with the following permissions
search -> IAM -> left side click on user -> create user

</br>
<img width="984" height="424" alt="image" src="https://github.com/user-attachments/assets/4d760cf6-eed2-4db8-9fa1-59617a9cc01e" />

</br>

click on attach policy directly:

</br>

<img width="1398" height="346" alt="image" src="https://github.com/user-attachments/assets/0d5ff012-e0fd-4e66-ae38-a4d3cbeb31fc" />

</br>

```

AdministratorAccess
AmazonEC2FullAccess
AmazonECS_FullAccess
AmazonEKS_CNI_Policy
AmazonEKSClusterPolicy
AmazonEKSComputePolicy
AmazonEKSWorkerNodePolicy
AWSCloudFormationFullAccess

```
## step2: after that -> create user -> security credentials
create access key -> click and create a access key
