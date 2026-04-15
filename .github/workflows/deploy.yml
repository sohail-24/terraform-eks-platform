name: 🚀 EKS ZERO-MANUAL DEPLOY PIPELINE

on:
  workflow_dispatch:
  push:
    branches: [ main ]

# ✅ Prevent parallel runs (VERY IMPORTANT)
concurrency:
  group: eks-deploy
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 150

    env:
      AWS_REGION: ap-south-1
      CLUSTER_NAME: aws_eks-eks
      NODEGROUP_NAME: aws_eks-eks-nodes

    steps:

    # -------------------------------
    # SETUP
    # -------------------------------
    - uses: actions/checkout@v4
    - uses: hashicorp/setup-terraform@v3
    - uses: azure/setup-kubectl@v4

    - uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    # -------------------------------
    # TERRAFORM
    # -------------------------------
    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan

    - name: Terraform Apply
      run: terraform apply -auto-approve

    # -------------------------------
    # EKS READY
    # -------------------------------
    - name: Wait Cluster
      run: aws eks wait cluster-active --name $CLUSTER_NAME

    - name: Configure kubeconfig
      run: aws eks update-kubeconfig --name $CLUSTER_NAME

    - name: Verify Cluster Access
      run: kubectl get nodes

    - name: Wait Nodegroup
      run: |
        aws eks wait nodegroup-active \
          --cluster-name $CLUSTER_NAME \
          --nodegroup-name $NODEGROUP_NAME

    - name: Wait Nodes Ready
      run: kubectl wait --for=condition=Ready nodes --all --timeout=600s

    # -------------------------------
    # CSI DRIVER (FIXED PROPERLY)
    # -------------------------------
   

    # -------------------------------
    # INSTALL ARGOCD
    # -------------------------------
    

    # -------------------------------
    # DEPLOY APPLICATION
    # -------------------------------
    - name: Apply Argo App
      run: kubectl apply -f argocd/app.yaml

    - name: Wait for ArgoCD Sync
      run: |
        echo "⏳ Waiting for ArgoCD sync..."

        for i in {1..40}; do
          STATUS=$(kubectl get application django-ecommerce -n argocd -o jsonpath='{.status.sync.status}')

          if [ "$STATUS" = "Synced" ]; then
            echo "✅ ArgoCD Synced"
            exit 0
          fi

          echo "Waiting sync... ($i)"
          sleep 15
        done

        echo "❌ ArgoCD sync failed"
        kubectl get application django-ecommerce -n argocd -o yaml
        exit 1

    # -------------------------------
    # LOAD BALANCER
    # -------------------------------
    - name: Wait LoadBalancer
      run: |
        echo "⏳ Waiting for LoadBalancer..."

        for i in {1..40}; do
          LB=$(kubectl get svc django -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

          if [ ! -z "$LB" ]; then
            echo "🌍 Application URL: http://$LB"
            exit 0
          fi

          echo "Waiting LB... ($i)"
          sleep 15
        done

        echo "❌ LoadBalancer not ready"
        kubectl get svc -n ecommerce
        exit 1
