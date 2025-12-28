function showNotification(message, type) {
    const alertContainer = document.getElementById('alert-container');
    const alert = document.createElement('div');
    let icon = "";
    if(type === 'success') icon = '<i class="fa-solid fa-check-circle" style="margin-right:10px"></i>';
    if(type === 'error') icon = '<i class="fa-solid fa-triangle-exclamation" style="margin-right:10px"></i>';

    alert.className = `alert ${type}`;
    alert.innerHTML = `${icon} <span>${message}</span>`;
    
    alertContainer.appendChild(alert); 

    setTimeout(() => {
        alert.classList.add('show');
    }, 10); 

    setTimeout(() => {
        alert.classList.remove('show');
        setTimeout(() => {
            alert.remove();
        }, 500); 
    }, 5000); 
}
window.addEventListener('message', function(event) {
    const data = event.data;
    const interactionText = document.getElementById('interaction-text');
    const processUI = document.getElementById('process-ui');
    const actionLabel = document.getElementById('action-label');
    const processLabel = document.getElementById('process-label');
    const progressBar = document.getElementById('progress-fill');

    switch (data.type) {
        case 'setText':
            if (data.show) {
                actionLabel.textContent = data.text;
                interactionText.style.display = 'flex'; 
            } else {
                interactionText.style.display = 'none';
            }
            break;
        case 'startProcess':
            processLabel.textContent = data.text;
            progressBar.style.width = '0%';
            processUI.style.display = 'block';
            break;
        case 'updateProcess':
            progressBar.style.width = data.progress + '%';
            break;
        case 'stopProcess':
            progressBar.style.width = '100%'; 
            setTimeout(() => { processUI.style.display = 'none'; }, 200);
            break;
        case 'showNotification': 
            showNotification(data.message, data.notificationType);
            break;
    }
});